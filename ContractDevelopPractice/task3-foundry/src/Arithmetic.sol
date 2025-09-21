// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Arithmetic {
    event Addition(uint256 indexed a, uint256 indexed b, uint256 result);
    event Subtraction(uint256 indexed a, uint256 indexed b, uint256 result);
    
    
    function add(uint256 a, uint256 b) public returns (uint256) {
        uint256 result = a + b;
        emit Addition(a, b, result);
        return result;
    }

    function sub(uint256 a, uint256 b) public returns (uint256) {
        require(a >= b, "Underflow protection");
        uint256 result = a - b;
        emit Subtraction(a, b, result);
        return result;
    }
}
