// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./NFTAuction.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

//拍卖工厂合约
contract NFTAuctionFactory is Initializable,OwnableUpgradeable,UUPSUpgradeable {
    //拍卖合约地址列表
    address[] public auctions;
    //拍卖合约信息，KEY:拍卖ID
    mapping(uint256 tokenId => NFTAuction auction) public auctionMap;
    // 管理员（与 Owner 可区分，只有 owner 能升级/换实现）
    address public admin;
    // 当前使用的逻辑实现地址（用于后续新建）
    address public auctionImplementation;
     // 跨链接收者配置
    mapping(uint64 => address) public chainReceivers; // chainSelector => receiver address
    uint64[] public supportedChains;
    // CCIP配置 (只需要router，不需要LINK token因为使用ETH支付费用)
    IRouterClient public s_router;

    event AuctionCreated(address indexed nftContract,uint256 tokenId,address indexed auctionAddress);
    event AdminChanged(address indexed newAdmin);
    event AuctionImplementationUpdated(address indexed oldImpl, address indexed newImpl);
    event ChainReceiverSet(uint64 indexed chainSelector, address indexed receiver);
    event CrossChainMessageSent(uint256 indexed tokenId, uint64 indexed dstChain, bytes32 messageId);

    function initialize(address _auctionImplementation,address _router) initializer public {
        __Ownable_init();
        __UUPSUpgradeable_init();
        admin = msg.sender;
        auctionImplementation = _auctionImplementation;
        s_router = IRouterClient(_router);
    }

    function setAdmin(address _admin) external onlyOwner {
        admin = _admin;
        emit AdminChanged(_admin);
    }

    function setAuctionImplementation(address _newImplementation) external onlyOwner {
        require(_newImplementation != address(0), "impl zero");
        address old = auctionImplementation;
        auctionImplementation = _newImplementation;
        emit AuctionImplementationUpdated(old, _newImplementation);
    }

    function setChainReceiver(uint64 _chainSelector, address _receiver) external onlyOwner {
         if (chainReceivers[_chainSelector] == address(0)) {
            supportedChains.push(_chainSelector);
        }
        chainReceivers[_chainSelector] = _receiver;
        emit ChainReceiverSet(_chainSelector, _receiver);
    }

    //创建新的拍卖合约
    function createAuction(
        uint256 _duration,
        uint256 _startPrice,
        address _nftAddress,
        uint256 _tokenId,
        address _ethPriceFeed,
        uint256 _defaultFeePercentage,
        address _feeRecipient,
        address _paymentToken,
        bool _crossChainEnabled
    ) external returns(address) {
        require(msg.sender==admin,"only admin can create auction contract");
        require(address(auctionMap[_tokenId]) == address(0), "auction already exists for this token");
         require(auctionImplementation != address(0), "impl not set");

        //创建代理合约
        //初始化数据（与 NFTAuction.initialize(...) 签名保持一致）
        bytes memory initData = abi.encodeWithSignature(
            "initialize(address,address,uint256,address)",
            address(s_router),
            _ethPriceFeed,
            _defaultFeePercentage,
            _feeRecipient
        );

        ERC1967Proxy proxy = new ERC1967Proxy(auctionImplementation, initData);
        NFTAuction auction = NFTAuction(address(proxy));

        auction.createAuction(_duration, _startPrice, _nftAddress, _tokenId, _paymentToken,_crossChainEnabled);

        auctions.push(address(auction));
        auctionMap[_tokenId] = auction;
        emit AuctionCreated(_nftAddress, _tokenId, address(auction));
         // 如果启用跨链，广播拍卖创建消息
        if (_crossChainEnabled) {
            _broadcastAuctionCreated(_tokenId, _nftAddress, address(auction));
        }
        return address(auction);
    }

     // 广播拍卖创建到其他链
    function _broadcastAuctionCreated(uint256 _tokenId, address _nftContract, address _auctionAddress) internal {
        if (supportedChains.length == 0) return;
        bytes memory data = abi.encode("AUCTION_CREATED", _tokenId, _nftContract, _auctionAddress);
        
         for (uint256 i = 0; i < supportedChains.length; i++) {
            uint64 chainId = supportedChains[i];
            if (chainReceivers[chainId] != address(0)) {
              _sendMessage(chainId, data,_tokenId);
            }
        }
    }

    function _sendMessage(uint64 _destinationChain, bytes memory _data,uint256 _tokenId) internal {
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
            emit CrossChainMessageSent(_tokenId, _destinationChain, messageId);
        }
    }

    //获取拍卖合约地址列表
    function getAuctions() external view returns(address[] memory) {
        return auctions;
    }

    function auctionsCount() external view returns (uint256) {
        return auctions.length;
    }

    // UUPS 升级授权
    function _authorizeUpgrade(address newImplementation) internal view override onlyOwner{
    }

     receive() external payable {}
}