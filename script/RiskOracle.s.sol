// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/RiskOracle.sol";

contract DeployRiskOracle is Script {
    function run() external {
        // Retrieve the private key from the environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Set up initial authorized senders
        address[] memory initialSenders = new address[](1);
        initialSenders[0] = address(0x2); // Replace with actual address

        // Set up initial update types
        string[] memory initialUpdateTypes = new string[](2);
        initialUpdateTypes[0] = "Type1";
        initialUpdateTypes[1] = "Type2";

        // Deploy the RiskOracle contract
        RiskOracle riskOracle = new RiskOracle(
            initialSenders,
            initialUpdateTypes
        );

        // Log the address of the deployed contract
        console.log("RiskOracle deployed at:", address(riskOracle));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
