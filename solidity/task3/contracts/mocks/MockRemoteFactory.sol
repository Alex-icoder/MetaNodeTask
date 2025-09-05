// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract MockRemoteFactory {
    event RemoteReceived(bytes32 indexed srcMsgId, string tag, uint256 tokenId, address nft, address auctionAddr);
    function mockReceive(bytes32 srcMsgId, bytes calldata raw) external {
        (string memory tag, uint256 tokenId, address nft, address auctionAddr) =
            abi.decode(raw,(string,uint256,address,address));
        emit RemoteReceived(srcMsgId, tag, tokenId, nft, auctionAddr);
    }
}