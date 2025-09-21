// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract ArithmeticOptimized1 {
    
    uint256 public lastResult;
    
    // 加法函数 - 移除事件触发
    function add(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = a + b;
        lastResult = result;
        return result;
    }
    
    // 减法函数 - 移除事件触发，使用unchecked块减少gas消耗
    function sub(uint256 a, uint256 b) public returns (uint256) {
        require(a >= b, "Underflow not allowed");
        uint256 result;
        unchecked {
            result = a - b;
        }
        return result;
    }
    
}
