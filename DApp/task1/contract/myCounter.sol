// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//计数器合约
contract MyCounter {
    uint256 public counter;

    constructor() {
        counter = 0;
    }

    function increment() public {
        counter += 1;
    }
}