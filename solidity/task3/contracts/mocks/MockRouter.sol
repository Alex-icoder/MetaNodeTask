// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";

contract MockRouter is IRouterClient {
    struct SentMessage {
        uint64 dstChain;
        address sender;
        address receiver;
        bytes data;
        uint256 fee;
        bytes32 messageId;
    }
    mapping(bytes32 => SentMessage) public messages;
    bytes32[] public messageIds;
    event MockCCIPSend(uint64 dstChain, bytes32 messageId, address receiver);

    function isChainSupported(uint64) external pure returns (bool){return true;}
    function getSupportedTokens(uint64) external pure returns (address[] memory arr){arr=new address[](0);}
    function getFee(uint64, Client.EVM2AnyMessage calldata) external pure returns (uint256){return 0;}
    function ccipSend(uint64 dstChain, Client.EVM2AnyMessage calldata msgData) external payable returns (bytes32){
        bytes32 id = keccak256(abi.encode(dstChain, block.timestamp, msg.sender, msgData.data));
        address receiver;
        assembly { receiver := mload(add(msgData.receiver, 20)) }
        messages[id] = SentMessage({
            dstChain: dstChain,
            sender: msg.sender,
            receiver: receiver,
            data: msgData.data,
            fee: msg.value,
            messageId: id
        });
        messageIds.push(id);
        emit MockCCIPSend(dstChain, id, receiver);
        return id;
    }
    function getMessageIds() external view returns (bytes32[] memory){return messageIds;}
}