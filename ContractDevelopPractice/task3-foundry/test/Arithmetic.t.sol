// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Arithmetic.sol";
import "../src/ArithmeticOptimized1.sol";

contract ArithmeticTest is Test {
    Arithmetic mm;
    ArithmeticOptimized1 mmOptimized;

    function setUp() public {
        mm = new Arithmetic();
        mmOptimized = new ArithmeticOptimized1();
    }

    function testAdd() public {
        uint256 gasStart = gasleft();
        uint256 result = mm.add(1, 2);
        uint256 gasUsed = gasStart - gasleft();
        assertEq(result, 3);
        console.log("Gas used for add", gasUsed);
    }

    function testSub() public {
        uint256 gasStart = gasleft();
        uint256 result = mm.sub(3, 1);
        uint256 gasUsed = gasStart - gasleft();
        assertEq(result, 2);
        console.log("Gas used for sub", gasUsed);
    }

    function testSubUnderflow() public {
        vm.expectRevert("Subtraction underflow");
        mm.sub(1, 2);
    }
}