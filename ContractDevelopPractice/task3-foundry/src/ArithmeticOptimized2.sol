// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ArithmeticOptimized2 {
    
    uint256 public lastResult;
    
     // 纯函数版本 - 不修改状态，不触发事件
    function add(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }
    
    
    function sub(uint256 a, uint256 b) public pure returns (uint256) {
        require(a >= b, "Underflow not allowed");
        return a - b;
    }
    
}
