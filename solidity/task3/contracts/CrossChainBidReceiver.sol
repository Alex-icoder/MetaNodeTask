// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";

//跨链出价接收合约
contract CrossChainBidReceiver is Initializable, OwnableUpgradeable, UUPSUpgradeable, CCIPReceiver {
    struct AuctionInfo {
        //NFT ID
        uint256 tokenId;
        address nftContract;
        address auctionContract;
        //最高出价
        uint256 highestBid;
        //最高出价者
        address highestBidder;
        bool exists;
    }

    // chainSelector => source contract
    mapping(uint64 => address) public sourceContracts; 
    // tokenId => auction info
    mapping(uint256 => AuctionInfo) public auctions; 
    // 用户ETH余额
    mapping(address => uint256) public userBalances; 
    // 退款ETH余额
    mapping(address => uint256) public refundBalances; 

    event AuctionSynced(uint256 indexed tokenId, address nftContract, address auctionContract);
    event BidSent(uint256 indexed tokenId, address bidder, uint256 amount);
    event BidUpdated(uint256 indexed tokenId, uint256 currentBid, address currentBidder);
    event RefundReceived(address indexed user, uint256 amount);

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
    
    function setSourceContract(uint64 _chainSelector, address _sourceContract) external onlyOwner {
        sourceContracts[_chainSelector] = _sourceContract;
    }

    // 用户存入ETH资金
    function depositFunds() external payable {
        userBalances[msg.sender] += msg.value;
    }

    // 提交跨链出价 (使用ETH)
    function submitBid(uint256 _tokenId, uint256 _bidAmount, uint64 _sourceChain) external payable {
        require(userBalances[msg.sender] >= _bidAmount, "Insufficient balance");
        require(auctions[_tokenId].exists, "Auction not found");
        require(_bidAmount > auctions[_tokenId].currentBid, "Bid too low");
        
        userBalances[msg.sender] -= _bidAmount;
        
        bytes memory data = abi.encode("BID", _tokenId, msg.sender, _bidAmount);
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(sourceContracts[_sourceChain]),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000})),
            feeToken: address(0) // 使用native token (ETH) 支付费用
        });
        
        IRouterClient router = IRouterClient(this.getRouter());
        uint256 fees = router.getFee(_sourceChain, message);
        
        require(msg.value >= fees, "Insufficient ETH for CCIP fees");
        router.ccipSend{value: fees}(_sourceChain, message);
        
        // 如果用户发送了多余的ETH，退还差额
        if (msg.value > fees) {
            payable(msg.sender).transfer(msg.value - fees);
        }
        
        emit BidSent(_tokenId, msg.sender, _bidAmount);
    }
    
    // 接收跨链消息
    function _ccipReceive(Client.Any2EVMMessage memory message) internal override {
        uint64 sourceChain = message.sourceChainSelector;
        address sender = abi.decode(message.sender, (address));
        
        require(sourceContracts[sourceChain] == sender, "Unauthorized source");
        
        string memory messageType;
        (messageType) = abi.decode(message.data, (string));
        
        if (keccak256(abi.encodePacked(messageType)) == keccak256(abi.encodePacked("AUCTION_CREATED"))) {
            _handleAuctionCreated(message.data);
        } else if (keccak256(abi.encodePacked(messageType)) == keccak256(abi.encodePacked("BID_UPDATE"))) {
            _handleBidUpdate(message.data);
        } else if (keccak256(abi.encodePacked(messageType)) == keccak256(abi.encodePacked("REFUND"))) {
            _handleRefund(message.data);
        }
    }
    
    function _handleAuctionCreated(bytes memory _data) internal {
        (, uint256 tokenId, address nftContract, address auctionContract) = 
            abi.decode(_data, (string, uint256, address, address));
        
        auctions[tokenId] = AuctionInfo({
            tokenId: tokenId,
            nftContract: nftContract,
            auctionContract: auctionContract,
            highestBid: 0,
            highestBidder: address(0),
            exists: true
        });
        
        emit AuctionSynced(tokenId, nftContract, auctionContract);
    }
    
    function _handleBidUpdate(bytes memory _data) internal {
        (, uint256 tokenId, uint256 highestBid, address highestBidder,) = 
            abi.decode(_data, (string, uint256, uint256, address, uint64));
        
        if (auctions[tokenId].exists) {
            auctions[tokenId].highestBid = currentBid;
            auctions[tokenId].highestBidder = currentBidder;
            emit BidUpdated(tokenId, currentBid, currentBidder);
        }
    }
    
    function _handleRefund(bytes memory _data) internal {
        (, address bidder, uint256 amount) = 
            abi.decode(_data, (string, address, uint256));
        
        refundBalances[bidder] += amount;
        emit RefundReceived(bidder, amount);
    }
    
    // 提取ETH资金
    function withdrawFunds(uint256 _amount) external {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        userBalances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }
    
    // 提取ETH退款
    function withdrawRefund() external {
        uint256 amount = refundBalances[msg.sender];
        require(amount > 0, "No refund available");
        refundBalances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }
    
    // 查询函数
    function getAuctionInfo(uint256 _tokenId) external view returns (AuctionInfo memory) {
        return auctions[_tokenId];
    }
    
    function getUserBalance(address _user) external view returns (uint256) {
        return userBalances[_user];
    }
    
    function getRefundBalance(address _user) external view returns (uint256) {
        return refundBalances[_user];
    }
    
    // 估算CCIP费用
    function estimateCCIPFee(uint256 _tokenId, uint256 _bidAmount, uint64 _sourceChain) external view returns (uint256) {
        bytes memory data = abi.encode("BID", _tokenId, msg.sender, _bidAmount);
        
        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(sourceContracts[_sourceChain]),
            data: data,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000})),
            feeToken: address(0)
        });
        
        IRouterClient router = IRouterClient(this.getRouter());
        return router.getFee(_sourceChain, message);
    }
    
    receive() external payable {}
}
