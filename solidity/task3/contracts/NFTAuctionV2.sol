// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./NFTAuction.sol";

contract NFTAuctionV2 is NFTAuction {
    string public versionTag;
    function setVersionTag(string calldata v) external onlyOwner {
        versionTag = v;
    }
    function getVersionTag() external view returns(string memory){
        return versionTag;
    }
      function sayHello() public view returns(string memory){
        return "Hello world";
    }
}