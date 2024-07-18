// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/RiskOracle.sol";

contract RiskOracleScript is Script {
    function setUp() external {}

    function run() external {
        vm.startBroadcast();

        address[] memory initialSenders = new address[](1);
        initialSenders[0] = address(0x2);
        string[] memory initialUpdateTypes = new string[](2);
        initialUpdateTypes[0] = "Type1";
        initialUpdateTypes[1] = "Type2";

        RiskOracle riskOracle = new RiskOracle(initialSenders, initialUpdateTypes);

        vm.stopBroadcast();
    }
}
