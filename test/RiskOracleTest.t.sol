// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

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
        for (uint256 i = 0; i < types.length; i++) {
            if (keccak256(abi.encodePacked(types[i])) == keccak256(abi.encodePacked("Type3"))) {
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
        bytes memory additionalData = abi.encodePacked("additionalData");
        vm.prank(address(0x4)); // Unauthorized address
        vm.expectRevert();
        riskOracle.publishRiskParameterUpdate("ref1", newValue, "Type1", abi.encodePacked("market1"), additionalData);
    }

    function testAuthorizedCanPublishUpdates() public {
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory additionalData = abi.encodePacked("additionalData");
        vm.prank(authorizedSender); // Set msg.sender to authorized sender
        riskOracle.publishRiskParameterUpdate("ref1", newValue, "Type1", abi.encodePacked("market1"), additionalData);
        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByType("Type1");
        assertEq(update.referenceId, "ref1");
        assertEq(update.newValue, newValue);
    }

    function testGetUpdateById() public {
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory additionalData = abi.encodePacked("additionalData");
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref1", newValue, "Type1", abi.encodePacked("market1"), additionalData);
        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(1);
        assertEq(update.referenceId, "ref1");
        assertEq(update.newValue, newValue);
    }

    function testGetLatestUpdateByType() public {
        bytes memory newValue1 = abi.encodePacked("newValue1");
        bytes memory newValue2 = abi.encodePacked("newValue2");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref1", newValue1, "Type1", abi.encodePacked("market1"), additionalData);

        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref2", newValue2, "Type1", abi.encodePacked("market2"), additionalData);

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByType("Type1");
        assertEq(update.referenceId, "ref2");
        assertEq(update.newValue, newValue2);
    }

    function testGetLatestUpdateByParameterAndMarket() public {
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory market = abi.encodePacked("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref1", newValue, "Type1", market, additionalData);

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByParameterAndMarket("Type1", market);
        assertEq(update.referenceId, "ref1");
        assertEq(update.newValue, newValue);
    }

    function testPublishRiskParameterUpdate() public {
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory market = abi.encodePacked("market");
        bytes memory additionalData = abi.encodePacked("additionalData");
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref1", newValue, "Type1", market, additionalData);

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(1);
        assertEq(update.referenceId, "ref1");
        assertEq(update.newValue, newValue);
        assertEq(update.updateType, "Type1");
        assertEq(update.market, market);
        assertEq(update.additionalData, additionalData);
    }

    function testPublishBulkRiskParameterUpdates() public {
        string[] memory referenceIds = new string[](1);
        referenceIds[0] = "ref1";
        bytes[] memory newValues = new bytes[](1);
        newValues[0] = abi.encodePacked("newValue");
        string[] memory updateTypes = new string[](1);
        updateTypes[0] = "Type1";
        bytes[] memory markets = new bytes[](1);
        markets[0] = abi.encodePacked("market");
        bytes[] memory additionalData = new bytes[](1);
        additionalData[0] = abi.encodePacked("additionalData");

        vm.prank(authorizedSender);
        riskOracle.publishBulkRiskParameterUpdates(referenceIds, newValues, updateTypes, markets, additionalData);

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(1);
        assertEq(update.referenceId, "ref1");
        assertEq(update.newValue, newValues[0]);
        assertEq(update.updateType, updateTypes[0]);
        assertEq(update.market, markets[0]);
        assertEq(update.additionalData, additionalData[0]);
    }

    function testCannotRemoveNonExistentAuthorizedSender() public {
        vm.prank(owner);
        vm.expectRevert();
        riskOracle.removeAuthorizedSender(address(0x5));
    }

    function testCannotPublishUpdateWithEmptyUpdateType() public {
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory additionalData = abi.encodePacked("additionalData");
        vm.prank(authorizedSender);
        vm.expectRevert();
        riskOracle.publishRiskParameterUpdate("ref1", newValue, "", abi.encodePacked("market1"), additionalData);
    }

    function testPreviousValueIsCorrectForSpecificMarketAndType() public {
        bytes memory market1 = abi.encodePacked("market1");
        bytes memory market2 = abi.encodePacked("market2");
        bytes memory newValue1 = abi.encodePacked("value1");
        bytes memory newValue2 = abi.encodePacked("value2");
        bytes memory newValue3 = abi.encodePacked("value3");
        bytes memory newValue4 = abi.encodePacked("value4");

        // Publish first update for market1 and type1
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref1", newValue1, "Type1", market1, abi.encodePacked("additionalData1"));

        // Publish second update for market1 and type1
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref2", newValue2, "Type1", market1, abi.encodePacked("additionalData2"));

        // Publish first update for market2 and type1
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref3", newValue3, "Type1", market2, abi.encodePacked("additionalData3"));

        // Publish first update for market1 and type1
        vm.prank(authorizedSender);
        riskOracle.publishRiskParameterUpdate("ref4", newValue4, "Type1", market1, abi.encodePacked("additionalData4"));

        // Fetch the latest update for market1 and type1
        RiskOracle.RiskParameterUpdate memory latestUpdateMarket1Type1 =
            riskOracle.getLatestUpdateByParameterAndMarket("Type1", market1);
        assertEq(latestUpdateMarket1Type1.previousValue, newValue2);

        // Fetch the latest update for market2 and type1
        RiskOracle.RiskParameterUpdate memory latestUpdateMarket2Type1 =
            riskOracle.getLatestUpdateByParameterAndMarket("Type1", market2);
        assertEq(latestUpdateMarket2Type1.previousValue, bytes(""));
    }
}
