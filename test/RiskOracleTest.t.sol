// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "./RiskOracleHarness.sol";

contract RiskOracleTest is Test {
    RiskOracleHarness public riskOracle;

    address public OWNER = makeAddr("Owner");
    address public NOT_OWNER = makeAddr("Not Owner");
    address public AUTHORIZED_SENDER = makeAddr("Authorized Sender");
    address public ANOTHER_AUTHORIZED_SENDER =
        makeAddr("Another Authorized Sender");
    address public NOT_AUTHORIZED_SENDER = makeAddr("Not Authorized Sender");

    string[] public initialUpdateTypes = ["Type1", "Type2"];
    string public anotherUpdateType = "Type3";
    address[] public initialSenders = [AUTHORIZED_SENDER];

    function setUp() public {
        // Set up the risk oracle with initial settings
        vm.prank(OWNER);
        riskOracle = new RiskOracleHarness(initialSenders, initialUpdateTypes);
    }

    function test_OwnerCanAddAuthorizedSender() public {
        // Owner should be able to add a new authorized sender
        vm.prank(OWNER);
        riskOracle.addAuthorizedSender(ANOTHER_AUTHORIZED_SENDER);
        assertTrue(riskOracle.isAuthorized(ANOTHER_AUTHORIZED_SENDER));
    }

    function testFuzz_OwnerCanAddAuthorizedSender(address sender) public {
        // Fuzz test: owner adds a random authorized sender
        vm.assume(sender != AUTHORIZED_SENDER);
        vm.prank(OWNER);
        riskOracle.addAuthorizedSender(sender);
        assertTrue(riskOracle.isAuthorized(sender));
    }

    function test_NonOwnerCannotAddAuthorizedSender() public {
        // Non-owner should not be able to add a new authorized sender
        vm.startPrank(NOT_OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                NOT_OWNER
            )
        );
        riskOracle.addAuthorizedSender(ANOTHER_AUTHORIZED_SENDER);
        vm.stopPrank();
        assertFalse(riskOracle.isAuthorized(ANOTHER_AUTHORIZED_SENDER));
    }

    function testFuzz_NonOwnerCannotAddAuthorizedSender(
        address caller,
        address sender
    ) public {
        // Fuzz test: non-owner cannot add an authorized sender
        vm.assume(
            caller != OWNER &&
                caller != AUTHORIZED_SENDER &&
                caller != ANOTHER_AUTHORIZED_SENDER
        );
        vm.assume(
            sender != OWNER &&
                sender != AUTHORIZED_SENDER &&
                sender != ANOTHER_AUTHORIZED_SENDER
        );

        vm.startPrank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                caller
            )
        );
        riskOracle.addAuthorizedSender(sender);
        vm.stopPrank();

        assertFalse(riskOracle.isAuthorized(sender));
    }

    function test_OwnerCanRemoveAuthorizedSender() public {
        // Owner should be able to remove an authorized sender
        vm.prank(OWNER);
        riskOracle.removeAuthorizedSender(AUTHORIZED_SENDER);
        assertFalse(riskOracle.isAuthorized(AUTHORIZED_SENDER));
    }

    function test_NonOwnerCannotRemoveAuthorizedSender() public {
        // Non-owner should not be able to remove an authorized sender
        vm.startPrank(NOT_OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                NOT_OWNER
            )
        );
        riskOracle.removeAuthorizedSender(AUTHORIZED_SENDER);
        vm.stopPrank();
    }

    function test_CannotAddExistingAuthorizedSender() public {
        // Ensures a sender cannot be added twice
        vm.startPrank(OWNER);
        vm.expectRevert("Sender already authorized.");
        riskOracle.addAuthorizedSender(AUTHORIZED_SENDER);
        vm.stopPrank();
        assertTrue(riskOracle.isAuthorized(AUTHORIZED_SENDER));
    }

    function test_CannotRemoveNonExistentAuthorizedSender() public {
        // Ensures trying to remove an unauthorized sender fails
        vm.startPrank(OWNER);
        vm.expectRevert("Sender not authorized.");
        riskOracle.removeAuthorizedSender(NOT_AUTHORIZED_SENDER);
        vm.stopPrank();
        assertFalse(riskOracle.isAuthorized(NOT_AUTHORIZED_SENDER));
    }

    function test_OwnerCanAddUpdateType() public {
        // Owner should be able to add valid update type
        vm.prank(OWNER);
        riskOracle.addUpdateType(anotherUpdateType);

        assertTrue(riskOracle.exposed_validUpdateTypes(anotherUpdateType));
        assertTrue(inArray(anotherUpdateType, riskOracle.getAllUpdateTypes()));
    }

    function testFuzz_OwnerCanAddUpdateType(string memory updateType) public {
        // Fuzz test: Owner adding a random update type
        vm.assume(bytes(updateType).length <= 64);
        vm.assume(
            keccak256(abi.encodePacked(updateType)) !=
                keccak256(abi.encodePacked(initialUpdateTypes[0])) &&
                keccak256(abi.encodePacked(updateType)) !=
                keccak256(abi.encodePacked(initialUpdateTypes[1]))
        );

        vm.prank(OWNER);
        riskOracle.addUpdateType(updateType);

        assertTrue(riskOracle.exposed_validUpdateTypes(updateType));
        assertTrue(inArray(updateType, riskOracle.getAllUpdateTypes()));
    }

    function test_NonOwnerCannotAddUpdateType() public {
        // Non-owner should not be able to add a new update type
        vm.startPrank(NOT_OWNER);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                NOT_OWNER
            )
        );
        riskOracle.addUpdateType(anotherUpdateType);
        vm.stopPrank();

        assertFalse(riskOracle.exposed_validUpdateTypes(anotherUpdateType));
    }

    function testFuzz_NonOwnerCannotAddUpdateType(
        address caller,
        string memory updateType
    ) public {
        // Fuzz test: non-owner cannot add a new update type
        vm.assume(caller != OWNER);
        vm.startPrank(caller);
        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                caller
            )
        );
        riskOracle.addUpdateType(updateType);
        vm.stopPrank();
        assertFalse(riskOracle.exposed_validUpdateTypes(updateType));
    }

    /*function test_AuthorizedCanPublishRiskParameterUpdates() public {
        bool isAuthorized = riskOracle.isAuthorized(AUTHORIZED_SENDER);
        assertTrue(isAuthorized, "AUTHORIZED_SENDER should be authorized.");
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue = abi.encodePacked("newValue");
        address market = makeAddr("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
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
        riskOracle.publishRiskParameterUpdate(
            referenceId,
            newValue,
            updateType,
            market,
            additionalData
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByParameterAndMarket(updateType, market);
        assertEq(update.newValue, newValue);
        assertEq(update.referenceId, referenceId);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateType);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, market);
        assertEq(update.additionalData, additionalData);
    }*/
    function test_AuthorizedCanPublishRiskParameterUpdates() public {
        // Ensure AUTHORIZED_SENDER is actually authorized
        assertTrue(
            riskOracle.isAuthorized(AUTHORIZED_SENDER),
            "AUTHORIZED_SENDER should be authorized."
        );

        // Define variables for the test.
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0]; // Assume initialUpdateTypes is setup properly
        bytes memory newValue = abi.encodePacked("newValue");
        address market = makeAddr("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        // Check if the updateType is valid.
        bool updateTypeValid = riskOracle.exposed_validUpdateTypes(updateType);
        assertTrue(updateTypeValid, "Invalid update type being used.");

        // Ensure the market and additional data are correctly shaped
        require(market != address(0), "Invalid market address.");

        // Proceed with the main logic.
        vm.prank(AUTHORIZED_SENDER);
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
        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            referenceId,
            newValue,
            updateType,
            market,
            additionalData
        );

        // Validate the state result.
        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByParameterAndMarket(updateType, market);
        assertEq(update.newValue, newValue, "newValue mismatch.");
        assertEq(update.referenceId, referenceId, "Reference ID mismatch.");
        assertEq(
            update.previousValue,
            "",
            "Mismatched previous value on the first record."
        );
        assertEq(
            update.updateType,
            updateType,
            "Mismatch in identified update type."
        );
        assertEq(
            update.updateId,
            riskOracle.updateCounter(),
            "updateCounter equals updateId on the last change."
        );
        assertEq(
            update.market,
            market,
            "Mismatch detected in provided market."
        );
        assertEq(
            update.additionalData,
            additionalData,
            "Final additionalData mismatch."
        );
    }

    function test_SimplifiedAuthorizedSenderCanPublish() public {
        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            "simpleRef",
            abi.encodePacked("simpleValue"),
            initialUpdateTypes[0],
            makeAddr("simpleMarket"),
            abi.encodePacked("simpleAdditionalData")
        );
    }

    function testFuzz_AuthorizedCanPublishRiskParameterUpdates(
        string memory referenceId,
        uint256 updateTypeIndex,
        bytes memory newValue,
        address market,
        bytes memory additionalData
    ) public {
        string memory updateType = initialUpdateTypes[
            bound(updateTypeIndex, 0, initialUpdateTypes.length - 1)
        ];

        vm.prank(AUTHORIZED_SENDER);
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
        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            referenceId,
            newValue,
            updateType,
            market,
            additionalData
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByParameterAndMarket(updateType, market);
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
            makeAddr("market1"),
            abi.encodePacked("additionalData")
        );
        assertEq(riskOracle.updateCounter(), 0);
    }

    function testFuzz_UnauthorizedCannotPublishRiskParameterUpdates(
        string memory referenceId,
        uint256 updateTypeIndex,
        bytes memory newValue,
        address market,
        bytes memory additionalData
    ) public {
        string memory updateType = initialUpdateTypes[
            bound(updateTypeIndex, 0, initialUpdateTypes.length - 1)
        ];

        vm.startPrank(NOT_AUTHORIZED_SENDER);
        vm.expectRevert("Unauthorized: Sender not authorized.");
        riskOracle.publishRiskParameterUpdate(
            referenceId,
            newValue,
            updateType,
            market,
            additionalData
        );
        vm.stopPrank();

        vm.expectRevert(
            "No update found for the specified parameter and market."
        );
        riskOracle.getLatestUpdateByParameterAndMarket(updateType, market);
        assertEq(riskOracle.updateCounter(), 0);
    }

    function test_CannotPublishRiskParameterUpdateWithEmptyUpdateType() public {
        vm.startPrank(AUTHORIZED_SENDER);
        vm.expectRevert("Unauthorized update type.");
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            abi.encodePacked("newValue"),
            "",
            makeAddr("market1"),
            abi.encodePacked("additionalData")
        );
        vm.stopPrank();
    }

    function test_GetUpdateById() public {
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue = abi.encodePacked("newValue");
        address market = makeAddr("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            referenceId,
            newValue,
            updateType,
            market,
            additionalData
        );
        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(
            riskOracle.updateCounter()
        );

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

    function test_GetLatestUpdateByParameterAndMarket() public {
        string memory referenceId = "ref1";
        string memory updateType = initialUpdateTypes[0];
        bytes memory newValue = abi.encodePacked("newValue");
        address market = makeAddr("market1");
        bytes memory additionalData = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            referenceId,
            newValue,
            updateType,
            market,
            additionalData
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle
            .getLatestUpdateByParameterAndMarket(updateType, market);
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
        address market = makeAddr("market1");
        address invalidMarket = makeAddr("InvalidMarket");

        vm.expectRevert(
            "No update found for the specified parameter and market."
        );
        riskOracle.getLatestUpdateByParameterAndMarket(updateType, market);

        vm.expectRevert(
            "No update found for the specified parameter and market."
        );
        riskOracle.getLatestUpdateByParameterAndMarket(invalidType, market);

        vm.expectRevert(
            "No update found for the specified parameter and market."
        );
        riskOracle.getLatestUpdateByParameterAndMarket(
            updateType,
            invalidMarket
        );

        vm.expectRevert(
            "No update found for the specified parameter and market."
        );
        riskOracle.getLatestUpdateByParameterAndMarket(
            invalidType,
            invalidMarket
        );
    }

    function test_PublishBulkRiskParameterUpdatesSingular() public {
        string[] memory referenceIds = new string[](1);
        referenceIds[0] = "ref1";
        bytes[] memory newValues = new bytes[](1);
        newValues[0] = abi.encodePacked("newValue");
        string[] memory updateTypes = new string[](1);
        updateTypes[0] = "Type1";
        address[] memory markets = new address[](1);
        markets[0] = makeAddr("market1");
        bytes[] memory additionalData = new bytes[](1);
        additionalData[0] = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishBulkRiskParameterUpdates(
            referenceIds,
            newValues,
            updateTypes,
            markets,
            additionalData
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(
            riskOracle.updateCounter()
        );
        assertEq(update.newValue, newValues[0]);
        assertEq(update.referenceId, referenceIds[0]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[0]);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, markets[0]);
        assertEq(update.additionalData, additionalData[0]);
    }

    function test_PublishBulkRiskParameterUpdatesMultipleSameUpdateType()
        public
    {
        string[] memory referenceIds = new string[](2);
        referenceIds[0] = "ref1";
        referenceIds[1] = "ref2";
        bytes[] memory newValues = new bytes[](2);
        newValues[0] = abi.encodePacked("newValue1");
        newValues[1] = abi.encodePacked("newValue2");
        string[] memory updateTypes = new string[](2);
        updateTypes[0] = initialUpdateTypes[0];
        updateTypes[1] = initialUpdateTypes[0];
        address[] memory markets = new address[](2);
        markets[0] = makeAddr("market1");
        markets[1] = makeAddr("market2");
        bytes[] memory additionalData = new bytes[](2);
        additionalData[0] = abi.encodePacked("additionalData");
        additionalData[1] = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishBulkRiskParameterUpdates(
            referenceIds,
            newValues,
            updateTypes,
            markets,
            additionalData
        );

        // Check the first update (should be as expected)
        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(
            riskOracle.updateCounter() - 1
        );
        assertEq(update.newValue, newValues[0]);
        assertEq(update.referenceId, referenceIds[0]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[0]);
        assertEq(update.updateId, riskOracle.updateCounter() - 1);
        assertEq(update.market, markets[0]);
        assertEq(update.additionalData, additionalData[0]);

        // Check the second update
        update = riskOracle.getUpdateById(riskOracle.updateCounter());
        assertEq(update.newValue, newValues[1]);
        assertEq(update.referenceId, referenceIds[1]);
        assertEq(update.previousValue, "");
        assertEq(update.updateType, updateTypes[1]);
        assertEq(update.updateId, riskOracle.updateCounter());
        assertEq(update.market, markets[1]);
        assertEq(update.additionalData, additionalData[1]);
    }

    function test_PublishBulkRiskParameterUpdatesSameTypeSameMarket() public {
        string[] memory referenceIds = new string[](2);
        referenceIds[0] = "ref1";
        referenceIds[1] = "ref2";
        bytes[] memory newValues = new bytes[](2);
        newValues[0] = abi.encodePacked("newValue1");
        newValues[1] = abi.encodePacked("newValue2");
        string[] memory updateTypes = new string[](2);
        updateTypes[0] = initialUpdateTypes[0];
        updateTypes[1] = initialUpdateTypes[0];
        address[] memory markets = new address[](2);
        markets[0] = makeAddr("market1");
        markets[1] = makeAddr("market1");
        bytes[] memory additionalData = new bytes[](2);
        additionalData[0] = abi.encodePacked("additionalData1");
        additionalData[1] = abi.encodePacked("additionalData2");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishBulkRiskParameterUpdates(
            referenceIds,
            newValues,
            updateTypes,
            markets,
            additionalData
        );

        // Check the first update
        RiskOracle.RiskParameterUpdate memory firstUpdate = riskOracle
            .getUpdateById(riskOracle.updateCounter() - 1);

        assertEq(firstUpdate.newValue, newValues[0]);
        assertEq(firstUpdate.referenceId, referenceIds[0]);
        assertEq(firstUpdate.previousValue, "");
        assertEq(firstUpdate.updateType, updateTypes[0]);
        assertEq(firstUpdate.updateId, riskOracle.updateCounter() - 1);
        assertEq(firstUpdate.market, markets[0]);
        assertEq(firstUpdate.additionalData, additionalData[0]);

        // Check the second update
        RiskOracle.RiskParameterUpdate memory secondUpdate = riskOracle
            .getUpdateById(riskOracle.updateCounter());

        assertEq(secondUpdate.newValue, newValues[1]);
        assertEq(secondUpdate.referenceId, referenceIds[1]);
        assertEq(secondUpdate.previousValue, newValues[0]); // same market, should use the previous value in the update.
        assertEq(secondUpdate.updateType, updateTypes[1]);
        assertEq(secondUpdate.updateId, riskOracle.updateCounter());
        assertEq(secondUpdate.market, markets[1]);
        assertEq(secondUpdate.additionalData, additionalData[1]);
    }

    function test_PublishBulkRiskParameterUpdatesMultipleDifferentUpdateType()
        public
    {
        string[] memory referenceIds = new string[](2);
        referenceIds[0] = "ref1";
        referenceIds[1] = "ref2";
        bytes[] memory newValues = new bytes[](2);
        newValues[0] = abi.encodePacked("newValue1");
        newValues[1] = abi.encodePacked("newValue2");
        string[] memory updateTypes = new string[](2);
        updateTypes[0] = initialUpdateTypes[0];
        updateTypes[1] = initialUpdateTypes[1];
        address[] memory markets = new address[](2);
        markets[0] = makeAddr("market1");
        markets[1] = makeAddr("market2");
        bytes[] memory additionalData = new bytes[](2);
        additionalData[0] = abi.encodePacked("additionalData");
        additionalData[1] = abi.encodePacked("additionalData");

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishBulkRiskParameterUpdates(
            referenceIds,
            newValues,
            updateTypes,
            markets,
            additionalData
        );

        RiskOracle.RiskParameterUpdate memory update = riskOracle.getUpdateById(
            riskOracle.updateCounter() - 1
        );
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
        address market1 = makeAddr("market1");
        address market2 = makeAddr("market2");
        bytes memory newValue1 = abi.encodePacked("value1");
        bytes memory newValue2 = abi.encodePacked("value2");
        bytes memory newValue3 = abi.encodePacked("value3");
        bytes memory newValue4 = abi.encodePacked("value4");
        string memory updateType = initialUpdateTypes[0];

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            "ref1",
            newValue1,
            updateType,
            market1,
            abi.encodePacked("additionalData1")
        );

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            "ref2",
            newValue2,
            updateType,
            market1,
            abi.encodePacked("additionalData2")
        );

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            "ref3",
            newValue3,
            updateType,
            market2,
            abi.encodePacked("additionalData3")
        );

        vm.prank(AUTHORIZED_SENDER);
        riskOracle.publishRiskParameterUpdate(
            "ref4",
            newValue4,
            updateType,
            market1,
            abi.encodePacked("additionalData4")
        );

        // Assertions follow

        RiskOracle.RiskParameterUpdate
            memory latestUpdateMarket1Type1 = riskOracle
                .getLatestUpdateByParameterAndMarket(updateType, market1);
        assertEq(latestUpdateMarket1Type1.previousValue, newValue2);

        RiskOracle.RiskParameterUpdate
            memory latestUpdateMarket2Type1 = riskOracle
                .getLatestUpdateByParameterAndMarket(updateType, market2);
        assertEq(latestUpdateMarket2Type1.previousValue, bytes(""));
    }
}
