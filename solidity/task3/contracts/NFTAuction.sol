// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract NFTAuction is Initializable,OwnableUpgradeable,UUPSUpgradeable,ReentrancyGuardUpgradeable,IERC721Receiver{
    // 拍卖信息结构
    struct Auction {
        //卖家
        address seller;
        //拍卖持续时间
        uint256 duration;
        //拍卖是否结束
        bool ended;
        //起拍价
        uint256 startPrice;
        //拍卖开始时间
        uint256 startTime;
        //最高出价
        uint256 highestBid;
        //最高出价者
        address highestBidder;
        //NFT合约地址
        address nftContract;
        //NFT ID
        uint256 tokenId;
        //address(0) 表示使用ETH支付，其他为ERC20
        address paymentToken;
        //平台手续费百分比
        uint256 feePercent; 
        //是否启用跨链
        bool crossChainEnabled;
        //出价者链ID
        uint64 bidderChain;
    }
    //拍卖信息，KEY:拍卖ID
    mapping(uint256 => Auction) public auctions;
    //下一个拍卖ID
    uint256 public nextAuctionId;
    //管理员
    address public admin;
    //Chianlink价格预言机 
    AggregatorV3Interface public ethPriceFeed; //ETH/USD 价格预言机
    mapping (address => AggregatorV3Interface) public tokenPriceFeeds;// IERC20代币价格预言机映射，KEY:代币地址

    //手续费相关
    uint256 public defaultFeePercentage; //默认手续费百分比
    address public feeRecipient; //手续费接收地址

    //CCIP配置 // chainSelector => receiver address
    mapping(uint64 => address) public chainReceivers;
    uint64[] public supportedChains;
    IRouterClient public s_router;

    event AuctionCreated(uint256 indexed auctionId,address indexed seller,address indexed nftContract,uint256 tokenId,uint256 startPrice,uint256 duration,address paymentToken,bool crossChainEnabled);
    event BidPlaced(uint256 indexed auctionId,address indexed bidder,uint256 amount,uint256 usdValue);
    event AuctionEnded(uint256 indexed auctionId,address indexed winner,uint256 finalPrice);
    event CrossChainMessageSent(uint256 indexed auctionId, uint64 targetChain, bytes32 messageId);

    function initialize(address _router,
                       address _ethPriceFeed,
                       uint256 _defaultFeePercentage,
                       address _feeRecipient) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        admin = msg.sender;
        ethPriceFeed = AggregatorV3Interface(_ethPriceFeed);
        defaultFeePercentage = _defaultFeePercentage;
        feeRecipient = _feeRecipient;
        s_router = IRouterClient(_router);
    }

    function setChainReceiver(uint64 _chainSelector, address _receiver) external onlyOwner {
        if (chainReceivers[_chainSelector] == address(0)) {
            supportedChains.push(_chainSelector);
        }
        chainReceivers[_chainSelector] = _receiver;
    }

    //创建拍卖
    function createAuction(uint256 _duration,
        uint256 _startPrice,
        address _nftAddress,
        uint256 _tokenId,
        address _paymentToken,
        bool _crossChainEnabled
        ) public nonReentrant {
        require(msg.sender==admin,"only admin can create auction");
        require(_duration > 300,"duration must be greater than 5 minutes");
        require(_startPrice > 0,"start price must be greater than 0");
         //转移NFT到拍卖合约
        IERC721(_nftAddress).safeTransferFrom(msg.sender,address(this),_tokenId);
        //计算动态手续费
        uint256  feePercentage = calculateDynamicFee(_startPrice,_paymentToken);

        auctions[nextAuctionId] = Auction({
            seller:msg.sender,
            duration:_duration,
            startPrice:_startPrice,
            ended:false,
            highestBid:0,
            highestBidder:address(0),
            startTime: block.timestamp,
            nftContract:_nftAddress,
            tokenId:_tokenId,
            paymentToken:_paymentToken,
            feePercentage:feePercentage,
            crossChainEnabled: _crossChainEnabled
        });
        emit AuctionCreated(nextAuctionId,msg.sender,_nftAddress,_tokenId,_startPrice,_duration,_paymentToken,_crossChainEnabled); 
        nextAuctionId++;
    }

    //本地出价
    function placeBid(uint256 _auctionId) external payable nonReentrant{
        _updateBid(_auctionId, msg.sender, msg.value, uint64(block.chainid));
    }

    //处理跨链出价
    function processCrossChainBid(
        uint256 _auctionId,
        address _bidder,
        uint256 _amount,
        uint64 _sourceChain
    ) external onlyOwner nonReentrant {
        _updateBid(_auctionId,_bidder, _amount, _sourceChain);
    }

    function _updateBid(uint256 _auctionId, address _bidder, uint256 _amount, uint64 _sourceChain) internal {
        Auction storage auction = auctions[_auctionId];
        require(!auction.ended, "Auction has ended");
        require(block.timestamp < auction.startTime + auction.duration, "Auction expired");
        require(auction.seller != _bidder, "Seller cannot bid");
        require(_amount > auction.highestBid, "Bid must be higher than current bid");

         uint256 bidAmount;
        if (auction.paymentToken == address(0)) {
            //使用ETH支付
            require(msg.value > 0 , "Must send ETH");
            bidAmount = msg.value;
        } else {
            //使用ERC20代币支付
            require(_amount > 0, "Must send ERC20 tokens");
            require(msg.value == 0, "Should not send ETH for token payment");
            bidAmount = _amount;
            //转移代币到合约
            IERC20(auction.paymentToken).transferFrom(msg.sender, address(this), bidAmount);
        }

        //判断出价是否大于当前最高价
        require(bidAmount > auction.highestBid && bidAmount > auction.startPrice,"bid must be greater than highest bid and start price");
        //退还之前的最高出价者
        if(auction.highestBidder != address(0)) {
             // 本链出价者
             if (auction.bidderChain == uint64(block.chainid)) {
                if (auction.paymentToken == address(0)) {
                  payable(auction.highestBidder).transfer(auction.highestBid);
                } else {
                  IERC20(auction.paymentToken).transfer(auction.highestBidder, auction.highestBid);
                }
             } else {
                // 跨链出价者，发送退款消息
                 _sendRefund(auction.highestBidder, auction.highestBid, auction.bidderChain);
             }
        }
        auction.highestBid = _amount;
        auction.highestBidder = _bidder;
        auction.bidderChain = _sourceChain;
        // 获取USD价值用于事件
        uint256 usdValue = getUSDValue(bidAmount, auction.paymentToken);
        emit BidPlaced(_auctionId, msg.sender, bidAmount, usdValue);
        // 如果启用跨链，广播出价更新
        if (auction.crossChainEnabled) {
            _broadcastBidUpdate();
        }
    }

    // 发送退款消息
    function _sendRefund(address _bidder, uint256 _amount, uint64 _targetChain) internal {
        bytes memory data = abi.encode("REFUND", _bidder, _amount);
        _sendMessage(_targetChain, data);
    }

     function _sendMessage(uint64 _destinationChain, bytes memory _data) internal {
        address receiver = chainReceivers[_destinationChain];
        if (receiver == address(0)) return;
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: _data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(0) // 使用native token (ETH) 支付费用
        });
        
        uint256 fees = s_router.getFee(_destinationChain, message);
        if (address(this).balance >= fees) {
            bytes32 messageId = s_router.ccipSend{value: fees}(_destinationChain, message);
            emit CrossChainMessageSent(auction.auctionId, _destinationChain, messageId);
        }
    }

     // 广播出价更新到其他链
    function _broadcastBidUpdate(uint256 _auctionId) internal {
        Auction storage auction = auctions[_auctionId];
        bytes memory data = abi.encode(
            "BID_UPDATE",
            auction.auctionId,
            auction.highestBid,
            auction.highestBidder,
            auction.bidderChain
        );

        // Iterate through supported chains using supportedChains
        for (uint64 i = 0; i < supportedChains.length; i++) {
            uint64 chainId = supportedChains[i];
            if (chainId != auction.bidderChain && // Skip bidder's chain
            chainReceivers[chainId] != address(0)) {
            _sendMessage(chainId, data);
            }
        }
    }

    // 发送跨链消息
    function _sendMessage(uint64 _destinationChain, bytes memory _data) internal {
        address receiver = chainReceivers[_destinationChain];
        if (receiver == address(0)) return;
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: _data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 200_000})),
            feeToken: address(0) // 使用native token (ETH) 支付费用
        });
        
        uint256 fees = s_router.getFee(_destinationChain, message);
        if (address(this).balance >= fees) {
            bytes32 messageId = s_router.ccipSend{value: fees}(_destinationChain, message);
            emit CrossChainMessageSent(auction.auctionId, _destinationChain, messageId);
        }
    }

    //结束拍卖
    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        //判断拍卖是否结束
        require(!auction.ended && auction.startTime + auction.duration <= block.timestamp,"auction not yet ended");
        
        if (auction.highestBidder != address(0)) {
             //转移NFT给最高出价者
            if (auction.bidderChain == uint64(block.chainid)) {
                IERC721(auction.nftContract).safeTransferFrom(address(this),auction.highestBidder,auction.tokenId);
            } else {
                // 跨链出价者，发送NFT转移消息
                bytes memory data = abi.encode("TRANSFER_NFT", auction.highestBidder, auction.nftContract, auction.tokenId);
                _sendMessage(auction.bidderChain, data);
            }
            
            //计算手续费
            uint256 fee = (auction.highestBid * auction.feePercentage) / 10000;
            uint256 sellerAmount = auction.highestBid - fee;

            //转移手续费给平台
            if (auction.paymentToken == address(0)) {
                if (fee > 0) {
                  payable(feeRecipient).transfer(fee);
                }
                //转移剩余资金给卖家
                payable(auction.seller).transfer(sellerAmount);
            } else {
                if (fee > 0) {
                    IERC20(auction.paymentToken).transfer(feeRecipient, fee);
                }
                //转移剩余资金给卖家
                IERC20(auction.paymentToken).transfer(auction.seller, sellerAmount);
            }
            emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            //无人出价，退还NFT给卖家
            IERC721(auction.nftContract).safeTransferFrom(address(this), auction.seller, auction.tokenId);
        }
        auction.ended = true;
        emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
    }

     //动态手续费计算
    function calculateDynamicFee(uint256 _startPrice,address _paymentToken) public view returns(uint256) {
        uint256 usdValue = getUSDValue(_startPrice,_paymentToken);
        if (usdValue >= 10000 * 1e8) { //>=$10000
            return 100;//1%
        } else if(usdValue >=1000 * 1e8) { //>=$1000
            return 200;//2%
        } else {
            return _defaultFeePercentage;
        }
    }

    //获取USD价值,返回精度 1e18
    function getUSDValue(uint256 _amount,address _paymentToken) public view returns(uint256) {
        if(_paymentToken == address(0)) { 
            //ETH支付
            (,int256 price,,,) = ethPriceFeed.latestRoundData();
            require(price > 0,"invalid ETH price");
            return (_amount * uint256(price)) / 1e18;
        } else {
            //ERC20代币支付
            AggregatorV3Interface priceFeed = tokenPriceFeeds[_paymentToken];
            require(address(priceFeed) != address(0),"no price feed for this token");
            (,int256 price,,,) = priceFeed.latestRoundData();
            return (_amount * uint256(price)) / 1e18;
        }
    }

    //设置代币价格预言机
    function setTokenPriceFeed(address _token,address _priceFeed) external onlyOwner {
        tokenPriceFeeds[_token] = AggregatorV3Interface(_priceFeed);
    }

    //设置默认手续费
    function setDefaultFeePercentage(uint256 _feePercent) external onlyOwner {
        require(_feePercent <= 1000, "Fee percentage too high"); //最大10%
        defaultFeePercentage = _feePercent;
    }

    //设置手续费接收地址
    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        require(_feeRecipient != address(0), "Invalid fee recipient");
        feeRecipient = _feeRecipient;
    }

    //获取拍卖信息
    function getAuction(uint256 _auctionId) external view returns (Auction memory) {
        return auctions[_auctionId];
    }

    //检查拍卖是否活跃
    function isAuctionActive(uint256 _auctionId) external view returns (bool) {
        Auction storage auction = auctions[_auctionId];
        return !auction.ended && auction.startTime + auction.duration > block.timestamp;
    }

    //实现IERC721Receiver接口，允许合约接收NFT
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    // UUPS 升级授权
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner{
    }
}