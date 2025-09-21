// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/Arithmetic.sol";
import "forge-std/Script.sol";

contract ArithmeticDeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        Arithmetic arithmetic = new Arithmetic();
        vm.stopBroadcast();
    }
}