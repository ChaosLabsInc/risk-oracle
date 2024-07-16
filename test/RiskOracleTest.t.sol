// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "forge-std/console.sol"; // Ensure the logger is included
import "../src/RiskOracle.sol";

contract RiskOracleTest is Test {
    RiskOracle public riskOracle;
    address public owner = address(0x1);
    address public authorizedSender = address(0x2);
    string[] public initialUpdateTypes = ["Type1", "Type2"];

    function setUp() public {
        address[] memory initialSenders = new address[](1);
        initialSenders[0] = authorizedSender;

        vm.startPrank(owner); // Start impersonating the owner
        riskOracle = new RiskOracle(initialSenders, initialUpdateTypes);
        vm.stopPrank(); // Stop impersonation
    }

    function testOnlyOwnerCanAddAuthorizedSender() public {
        vm.prank(owner); // Set msg.sender to owner for this transaction
        riskOracle.addAuthorizedSender(address(0x3));
        assertTrue(riskOracle.isAuthorized(address(0x3)));
    }

    function testNonOwnerCannotAddAuthorizedSender() public {
        vm.prank(address(0x4)); // Unauthorized address
        vm.expectRevert();
        riskOracle.addAuthorizedSender(address(0x3));
    }

    function testOnlyOwnerCanRemoveAuthorizedSender() public {
        vm.prank(owner); // Set msg.sender to owner for this transaction
        riskOracle.removeAuthorizedSender(authorizedSender);
        assertFalse(riskOracle.isAuthorized(authorizedSender));
    }

    function testNonOwnerCannotRemoveAuthorizedSender() public {
        vm.prank(owner); // Owner adds an authorized sender first
        riskOracle.addAuthorizedSender(address(0x3));

        vm.prank(address(0x4)); // Unauthorized address tries to remove
        vm.expectRevert();
        riskOracle.removeAuthorizedSender(address(0x3));
    }

    function testOwnerCanAddUpdateType() public {
        vm.prank(owner); // Set msg.sender to owner for this transaction
        riskOracle.addUpdateType("Type3");
        string[] memory types = riskOracle.getAllUpdateTypes();
        bool found;
        for (uint i = 0; i < types.length; i++) {
            if (
                keccak256(abi.encodePacked(types[i])) ==
                keccak256(abi.encodePacked("Type3"))
            ) {
                found = true;
                break;
            }
        }
        assertTrue(found);
    }

    function testNonOwnerCannotAddUpdateType() public {
        vm.prank(address(0x4)); // Unauthorized address
        vm.expectRevert();
        riskOracle.addUpdateType("Type3");
    }

    function testUnauthorizedCannotPublishUpdates() public {
        bytes memory newValue = abi.encodePacked("newValue");
        vm.prank(address(0x4)); // Unauthorized address
        vm.expectRevert();
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            newValue,
            "Type1",
            abi.encodePacked("market1")
        );
    }

    function testAuthorizedCanPublishUpdates() public {
        bytes memory newValue = abi.encodePacked("newValue");
        vm.prank(authorizedSender); // Set msg.sender to authorized sender
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            newValue,
            "Type1",
            abi.encodePacked("market1")
        );
        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByType("Type1");
        assertEq(update.referenceId, "ref1");
        assertEq(update.parameter, newValue);
    }

    function testFetchUpdateDetails() public {
        bytes memory newValue = abi.encodePacked("newValue");
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            newValue,
            "Type1",
            abi.encodePacked("market1")
        );
        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .fetchUpdateDetails(1);
        assertEq(update.referenceId, "ref1");
        assertEq(update.parameter, newValue);
    }

    function testGetLatestUpdateByType() public {
        bytes memory newValue1 = abi.encodePacked("newValue1");
        bytes memory newValue2 = abi.encodePacked("newValue2");

        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            newValue1,
            "Type1",
            abi.encodePacked("market1")
        );

        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate(
            "ref2",
            newValue2,
            "Type1",
            abi.encodePacked("market2")
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByType("Type1");
        assertEq(update.referenceId, "ref2");
        assertEq(update.parameter, newValue2);
    }

    function testGetLatestUpdateByParameterAndMarket() public {
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory market = abi.encodePacked("market1");
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            newValue,
            "Type1",
            market
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByParameterAndMarket("Type1", market);
        assertEq(update.referenceId, "ref1");
        assertEq(update.parameter, newValue);
    }
}
