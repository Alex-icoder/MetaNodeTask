// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
contract SimpleStorage {
    uint256 private v;
    event Stored(uint256 val);
    function set(uint256 val) public {
        v = val;
        emit Stored(val);
    }
    function get() public view returns (uint256) {
        return v;
    }
}