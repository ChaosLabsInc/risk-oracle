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
        address[] memory initialSenders = new address[](2);
        initialSenders[0] = 0x1234567890123456789012345678901234567890; // Replace with actual address
        initialSenders[1] = 0x0987654321098765432109876543210987654321; // Replace with actual address

        // Set up initial update types
        string[] memory initialUpdateTypes = new string[](3);
        initialUpdateTypes[0] = "LiquidationThreshold";
        initialUpdateTypes[1] = "CollateralFactor";
        initialUpdateTypes[2] = "BorrowLimit";

        // Deploy the RiskOracle contract
        RiskOracle riskOracle = new RiskOracle(initialSenders, initialUpdateTypes);

        // Log the address of the deployed contract
        console.log("RiskOracle deployed at:", address(riskOracle));

        // Stop broadcasting transactions
        vm.stopBroadcast();
    }
}
