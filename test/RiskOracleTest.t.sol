// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RiskOracleHarness.sol";

contract RiskOracleTest is Test {
    RiskOracleHarness public riskOracle;

    address public OWNER = makeAddr("Owner");
    address public NOT_OWNER = makeAddr("Not Owner");
    address public AUTHORIZED_SENDER = makeAddr("Authorized Sender");
    address public ANOTHER_AUTHORIZED_SENDER = makeAddr("Another Authorized Sender");
    address public NOT_AUTHORIZED_SENDER = makeAddr("Not Authorized Sender");

    string[] public initialUpdateTypes = ["Type1", "Type2"];
    string public anotherUpdateType = "Type3";
    address[] public initialSenders = [AUTHORIZED_SENDER];

    function setUp() public {
        vm.prank(OWNER);
        riskOracle = new RiskOracleHarness(initialSenders, initialUpdateTypes);
    }

    function test_OwnerCanAddAuthorizedSender() public {
        vm.prank(OWNER);
        riskOracle.addAuthorizedSender(ANOTHER_AUTHORIZED_SENDER);
        assertTrue(riskOracle.isAuthorized(ANOTHER_AUTHORIZED_SENDER));
    }

    function testFuzz_OwnerCanAddAuthorizedSender(address sender) public {
        vm.assume(sender != AUTHORIZED_SENDER);
        vm.prank(OWNER);
        riskOracle.addAuthorizedSender(sender);
        assertTrue(riskOracle.isAuthorized(sender));
    }

    function test_NonOwnerCannotAddAuthorizedSender() public {
        vm.startPrank(NOT_OWNER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, NOT_OWNER));
        riskOracle.addAuthorizedSender(ANOTHER_AUTHORIZED_SENDER);
        vm.stopPrank();
        assertFalse(riskOracle.isAuthorized(ANOTHER_AUTHORIZED_SENDER));
    }

    function testFuzz_NonOwnerCannotAddAuthorizedSender(address caller, address sender) public {
        vm.assume(caller != OWNER);
        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));
        riskOracle.addAuthorizedSender(sender);
        vm.stopPrank();
        assertFalse(riskOracle.isAuthorized(sender));
    }

    function test_OwnerCanRemoveAuthorizedSender() public {
        vm.prank(OWNER);
        riskOracle.removeAuthorizedSender(AUTHORIZED_SENDER);
        assertFalse(riskOracle.isAuthorized(AUTHORIZED_SENDER));
    }

    function test_NonOwnerCannotRemoveAuthorizedSender() public {
        vm.startPrank(NOT_OWNER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, NOT_OWNER));
        riskOracle.removeAuthorizedSender(AUTHORIZED_SENDER);
        vm.stopPrank();
    }

    function test_CannotAddExistingAuthorizedSender() public {
        vm.startPrank(OWNER);
        vm.expectRevert("Sender already authorized.");
        riskOracle.addAuthorizedSender(AUTHORIZED_SENDER);
        vm.stopPrank();
        assertTrue(riskOracle.isAuthorized(AUTHORIZED_SENDER));
    }

    function test_CannotRemoveNonExistentAuthorizedSender() public {
        vm.startPrank(OWNER);
        vm.expectRevert("Sender not authorized.");
        riskOracle.removeAuthorizedSender(NOT_AUTHORIZED_SENDER);
        vm.stopPrank();
        assertFalse(riskOracle.isAuthorized(NOT_AUTHORIZED_SENDER));
    }

    function test_OwnerCanAddUpdateType() public {
        vm.prank(OWNER);
        riskOracle.addUpdateType(anotherUpdateType);

        assertTrue(riskOracle.exposed_validUpdateTypes(anotherUpdateType));
        assertTrue(inArray(anotherUpdateType, riskOracle.getAllUpdateTypes()));
    }

    function testFuzz_OwnerCanAddUpdateType(string memory updateType) public {
        vm.assume(bytes(updateType).length <= 64);
        vm.assume(keccak256(abi.encodePacked(updateType)) != keccak256(abi.encodePacked(initialUpdateTypes[0])));
        vm.assume(keccak256(abi.encodePacked(updateType)) != keccak256(abi.encodePacked(initialUpdateTypes[1])));

        vm.prank(OWNER);
        riskOracle.addUpdateType(updateType);

        assertTrue(riskOracle.exposed_validUpdateTypes(updateType));
        assertTrue(inArray(updateType, riskOracle.getAllUpdateTypes()));
    }

    function test_NonOwnerCannotAddUpdateType() public {
        vm.startPrank(NOT_OWNER);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, NOT_OWNER));
        riskOracle.addUpdateType(anotherUpdateType);
        vm.stopPrank();
        assertFalse(riskOracle.exposed_validUpdateTypes(anotherUpdateType));
    }

    function testFuzz_NonOwnerCannotAddUpdateType(address caller, string memory updateType) public {
        vm.assume(caller != OWNER);
        vm.startPrank(caller);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, caller));
        riskOracle.addUpdateType(updateType);
        vm.stopPrank();
        if (
            keccak256(abi.encodePacked(updateType)) != keccak256(abi.encodePacked(initialUpdateTypes[0]))
                && keccak256(abi.encodePacked(updateType)) != keccak256(abi.encodePacked(initialUpdateTypes[1]))
        ) {
            assertFalse(riskOracle.exposed_validUpdateTypes(updateType));
        }
    }

    function test_AuthorizedCanPublishRiskParameterUpdates() public {
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory market = abi.encodePacked("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId,
            newValue,
            "",
            block.timestamp,
            updateType,
            riskOracle.updateCounter() + 1,
            market,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId, newValue, updateType, market, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByType(updateType);
        assertEq(update.newValue, newValue);
        assertEq(update.referenceId, referenceId);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateType);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market);
        assertEq(update.additionalData, additionalData);
    }

    function testFuzz_AuthorizedCanPublishRiskParameterUpdates(
        string memory referenceId,
        uint256 updateTypeIndex,
        bytes memory newValue,
        bytes memory market,
        bytes memory additionalData
    ) public {
        string memory updateType = initialUpdateTypes[bound(updateTypeIndex, 0, initialUpdateTypes.length - 1)];

        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId,
            newValue,
            "",
            block.timestamp,
            updateType,
            riskOracle.updateCounter() + 1,
            market,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId, newValue, updateType, market, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByType(updateType);
        assertEq(update.newValue, newValue);
        assertEq(update.referenceId, referenceId);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateType);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market);
        assertEq(update.additionalData, additionalData);
    }

    function test_UnauthorizedCannotPublishRiskParameterUpdates() public {
        vm.startPrank(NOT_AUTHORIZED_SENDER);
        vm.expectRevert("Unauthorized: Sender not authorized.");
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            abi.encodePacked("newValue"),
            "Type1",
            abi.encodePacked("market1"),
            abi.encodePacked("additionalData")
        );
        assertEq(riskOracle.updateCounter(), 0);
    }

    function testFuzz_UnauthorizedCannotPublishRiskParameterUpdates(
        string memory referenceId,
        uint256 updateTypeIndex,
        bytes memory newValue,
        bytes memory market,
        bytes memory additionalData
    ) public {
        string memory updateType = initialUpdateTypes[bound(updateTypeIndex, 0, initialUpdateTypes.length - 1)];

        vm.startPrank(NOT_AUTHORIZED_SENDER);
        vm.expectRevert("Unauthorized: Sender not authorized.");
        riskOracle.publishRiskParameterUpdate(referenceId, newValue, updateType, market, additionalData);
        vm.stopPrank();

        vm.expectRevert("No updates found for the specified type.");
        riskOracle.getLatestUpdateByType(updateType);
        assertEq(riskOracle.updateCounter(), 0);
    }

    function test_CannotPublishRiskParameterUpdateWithEmptyUpdateType() public {
        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectRevert("Unauthorized update type.");
        riskOracle.publishRiskParameterUpdate(
            "ref1", "newValue", "", abi.encodePacked("market1"), abi.encodePacked("additionalData")
        );
        vm.stopPrank();
    }

    function test_GetUpdateById() public {
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory market = abi.encodePacked("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(referenceId, newValue, updateType, market, additionalData);
        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(riskOracle.updateCounter());
        assertEq(update.newValue, newValue);
        assertEq(update.referenceId, referenceId);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateType);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market);
        assertEq(update.additionalData, additionalData);
    }

    function test_GetUpdateByIdReverts() public {
        assertEq(riskOracle.updateCounter(), 0);
        vm.expectRevert("Invalid update ID.");
        riskOracle.getUpdateById(0);
        vm.expectRevert("Invalid update ID.");
        riskOracle.getUpdateById(1);
    }

    function test_GetLatestUpdateByType() public {
        string memory referenceId1 = "ref1";
        string memory referenceId2 = "ref2";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue1 = abi.encodePacked("newValue1");
        bytes memory newValue2 = abi.encodePacked("newValue2");
        bytes memory market1 = abi.encodePacked("market1");
        bytes memory market2 = abi.encodePacked("market2");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId1,
            newValue1,
            "",
            block.timestamp,
            updateType,
            riskOracle.updateCounter() + 1,
            market1,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId1, newValue1, updateType, market1, additionalData);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId2,
            newValue2,
            newValue1,
            block.timestamp,
            updateType,
            riskOracle.updateCounter() + 1,
            market2,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId2, newValue2, updateType, market2, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByType(updateType);
        assertEq(update.newValue, newValue2);
        assertEq(update.referenceId, referenceId2);
        assertEq(update.previousValue, newValue1);
        assertEq(update.updateType, updateType);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market2);
        assertEq(update.additionalData, additionalData);
    }

    function test_GetLatestUpdateByTypeSandwich() public {
        string memory referenceId1 = "ref1";
        string memory referenceId2 = "ref2";
        string memory referenceId3 = "ref3";
        string memory updateType1 = initialUpdateTypes[0];
        string memory updateType2 = initialUpdateTypes[1];
        bytes memory newValue1 = abi.encodePacked("newValue1");
        bytes memory newValue2 = abi.encodePacked("newValue2");
        bytes memory newValue3 = abi.encodePacked("newValue3");
        bytes memory market1 = abi.encodePacked("market1");
        bytes memory market2 = abi.encodePacked("market2");
        bytes memory market3 = abi.encodePacked("market3");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId1,
            newValue1,
            "",
            block.timestamp,
            updateType1,
            riskOracle.updateCounter() + 1,
            market1,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId1, newValue1, updateType1, market1, additionalData);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId2,
            newValue2,
            "",
            block.timestamp,
            updateType2,
            riskOracle.updateCounter() + 1,
            market2,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId2, newValue2, updateType2, market2, additionalData);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId3,
            newValue3,
            newValue1,
            block.timestamp,
            updateType1,
            riskOracle.updateCounter() + 1,
            market3,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId3, newValue3, updateType1, market3, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getLatestUpdateByType(updateType1);
        assertEq(update.newValue, newValue3);
        assertEq(update.referenceId, referenceId3);
        assertEq(update.previousValue, newValue1);
        assertEq(update.updateType, updateType1);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market3);
        assertEq(update.additionalData, additionalData);
    }

    function test_GetLatestUpdateByTypeReverts() public {
        vm.expectRevert("No updates found for the specified type.");
        riskOracle.getLatestUpdateByType(initialUpdateTypes[0]);

        // now try an invalid type
        vm.expectRevert("No updates found for the specified type.");
        riskOracle.getLatestUpdateByType("InvalidType");
    }

    function test_GetLatestUpdateByParameterAndMarket() public {
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue = abi.encodePacked("newValue");
        bytes memory market = abi.encodePacked("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectEmit(true, true, true, true);
        emit RiskOracle.ParameterUpdated(
            referenceId,
            newValue,
            "",
            block.timestamp,
            updateType,
            riskOracle.updateCounter() + 1,
            market,
            additionalData
        );
        riskOracle.publishRiskParameterUpdate(referenceId, newValue, updateType, market, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update =
            riskOracle.getLatestUpdateByParameterAndMarket(updateType, market);
        assertEq(update.newValue, newValue);
        assertEq(update.referenceId, referenceId);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateType);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market);
        assertEq(update.additionalData, additionalData);
    }

    function test_GetLatestUpdateByParameterAndMarketReverts() public {
        string memory updateType = initialUpdateTypes[0];
        string memory invalidType = "InvalidType";
        bytes memory market = abi.encodePacked("market1");
        bytes memory invalidMarket = abi.encodePacked("InvalidMarket");

        // try a valid update type with no historical updates
        vm.expectRevert("No update found for the specified parameter and market.");
        riskOracle.getLatestUpdateByParameterAndMarket(updateType, market);

        // now try an invalid type
        vm.expectRevert("No update found for the specified parameter and market.");
        riskOracle.getLatestUpdateByParameterAndMarket(invalidType, market);

        // now try an invalid market
        vm.expectRevert("No update found for the specified parameter and market.");
        riskOracle.getLatestUpdateByParameterAndMarket(updateType, invalidMarket);

        // now try an invalid type & market
        vm.expectRevert("No update found for the specified parameter and market.");
        riskOracle.getLatestUpdateByParameterAndMarket(invalidType, invalidMarket);
    }

    function test_PublishBulkRiskParameterUpdatesSingular() public {
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

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishBulkRiskParameterUpdates(referenceIds, newValues, updateTypes, markets, additionalData);

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(riskOracle.updateCounter());
        assertEq(update.newValue, newValues[0]);
        assertEq(update.referenceId, referenceIds[0]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[0]);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, markets[0]);
        assertEq(update.additionalData, additionalData[0]);
    }

    function test_PublishBulkRiskParameterUpdatesMultipleSameUpdateType() public {
        string[] memory referenceIds = new string[](2);
        referenceIds[0] = "ref1";
        referenceIds[1] = "ref2";
        bytes[] memory newValues = new bytes[](2);
        newValues[0] = abi.encodePacked("newValue1");
        newValues[1] = abi.encodePacked("newValue2");
        string[] memory updateTypes = new string[](2);
        updateTypes[0] = initialUpdateTypes[0];
        updateTypes[1] = initialUpdateTypes[0];
        bytes[] memory markets = new bytes[](2);
        markets[0] = abi.encodePacked("market1");
        markets[1] = abi.encodePacked("market2");
        bytes[] memory additionalData = new bytes[](2);
        additionalData[0] = abi.encodePacked("additionalData");
        additionalData[1] = abi.encodePacked("additionalData");

        vm.startPrank(AUTHORIZED_SENDER);
        for (uint256 i = 0; i < referenceIds.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit RiskOracle.ParameterUpdated(
                referenceIds[i],
                newValues[i],
                i > 0 ? newValues[i - 1] : bytes(""),
                block.timestamp,
                updateTypes[i],
                riskOracle.updateCounter() + i + 1,
                markets[i],
                additionalData[i]
            );
        }
        riskOracle.publishBulkRiskParameterUpdates(referenceIds, newValues, updateTypes, markets, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(riskOracle.updateCounter() - 1);
        assertEq(update.newValue, newValues[0]);
        assertEq(update.referenceId, referenceIds[0]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[0]);
        assertEq(update.updateId, riskOracle.updateCounter() - 1);
        assertEq(update.market, markets[0]);
        assertEq(update.additionalData, additionalData[0]);

        update = riskOracle.getUpdateById(riskOracle.updateCounter());
        assertEq(update.newValue, newValues[1]);
        assertEq(update.referenceId, referenceIds[1]);
        assertEq(update.previousValue, newValues[0]);
        assertEq(update.updateType, updateTypes[1]);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, markets[1]);
        assertEq(update.additionalData, additionalData[1]);
    }

    function test_PublishBulkRiskParameterUpdatesMultipleDifferentUpdateType() public {
        string[] memory referenceIds = new string[](2);
        referenceIds[0] = "ref1";
        referenceIds[1] = "ref2";
        bytes[] memory newValues = new bytes[](2);
        newValues[0] = abi.encodePacked("newValue1");
        newValues[1] = abi.encodePacked("newValue2");
        string[] memory updateTypes = new string[](2);
        updateTypes[0] = initialUpdateTypes[0];
        updateTypes[1] = initialUpdateTypes[1];
        bytes[] memory markets = new bytes[](2);
        markets[0] = abi.encodePacked("market1");
        markets[1] = abi.encodePacked("market2");
        bytes[] memory additionalData = new bytes[](2);
        additionalData[0] = abi.encodePacked("additionalData");
        additionalData[1] = abi.encodePacked("additionalData");

        vm.startPrank(AUTHORIZED_SENDER);
        for (uint256 i = 0; i < referenceIds.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit RiskOracle.ParameterUpdated(
                referenceIds[i],
                newValues[i],
                "",
                block.timestamp,
                updateTypes[i],
                riskOracle.updateCounter() + i + 1,
                markets[i],
                additionalData[i]
            );
        }
        riskOracle.publishBulkRiskParameterUpdates(referenceIds, newValues, updateTypes, markets, additionalData);
        vm.stopPrank();

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(riskOracle.updateCounter() - 1);
        assertEq(update.newValue, newValues[0]);
        assertEq(update.referenceId, referenceIds[0]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[0]);
        assertEq(update.updateId, riskOracle.updateCounter() - 1);
        assertEq(update.market, markets[0]);
        assertEq(update.additionalData, additionalData[0]);

        update = riskOracle.getUpdateById(riskOracle.updateCounter());
        assertEq(update.newValue, newValues[1]);
        assertEq(update.referenceId, referenceIds[1]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[1]);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, markets[1]);
        assertEq(update.additionalData, additionalData[1]);
    }

    function test_PreviousValueIsCorrectForSpecificMarketAndType() public {
        bytes memory market1 = abi.encodePacked("market1");
        bytes memory market2 = abi.encodePacked("market2");
        bytes memory newValue1 = abi.encodePacked("value1");
        bytes memory newValue2 = abi.encodePacked("value2");
        bytes memory newValue3 = abi.encodePacked("value3");
        bytes memory newValue4 = abi.encodePacked("value4");
        string memory updateType = initialUpdateTypes[0];

        vm.startPrank(AUTHORIZED_SENDER);

        // Publish first update for market1 and type1
        riskOracle.publishRiskParameterUpdate(
            "ref1", newValue1, updateType, market1, abi.encodePacked("additionalData1")
        );

        // Publish second update for market1 and type1
        riskOracle.publishRiskParameterUpdate(
            "ref2", newValue2, updateType, market1, abi.encodePacked("additionalData2")
        );

        // Publish first update for market2 and type1
        riskOracle.publishRiskParameterUpdate(
            "ref3", newValue3, updateType, market2, abi.encodePacked("additionalData3")
        );

        // Publish first update for market1 and type1
        riskOracle.publishRiskParameterUpdate(
            "ref4", newValue4, updateType, market1, abi.encodePacked("additionalData4")
        );

        vm.stopPrank();

        // Fetch the latest update for market1 and type1
        RiskOracle.RiskParameterUpdate memory latestUpdateMarket1Type1 =
            riskOracle.getLatestUpdateByParameterAndMarket(updateType, market1);
        assertEq(latestUpdateMarket1Type1.previousValue, newValue2);

        // Fetch the latest update for market2 and type1
        RiskOracle.RiskParameterUpdate memory latestUpdateMarket2Type1 =
            riskOracle.getLatestUpdateByParameterAndMarket(updateType, market2);
        assertEq(latestUpdateMarket2Type1.previousValue, bytes(""));
    }
}
