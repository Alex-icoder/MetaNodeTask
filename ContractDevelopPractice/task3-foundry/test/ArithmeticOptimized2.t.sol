// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/ArithmeticOptimized2.sol";

contract ArithmeticOptimized2Test is Test {
    ArithmeticOptimized2 mm;

    function setUp() public {
        mm = new ArithmeticOptimized2();
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