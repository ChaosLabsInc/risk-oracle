// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {ExpectedErrors} from "./ExpectedErrors.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

import {RiskOracle} from "src/RiskOracle.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

abstract contract TargetFunctions is ExpectedErrors {
    using EnumerableSet for EnumerableSet.AddressSet;

    function riskOracle_addAuthorizedSender(address sender)
        public
        getMsgSender
        checkExpectedErrors(RISK_ORACLE_OWNER_ERRORS)
    {
        sender = _getRandomUser(sender);

        vm.prank(msgSender);
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.addAuthorizedSender, sender));

        if (success) {
            _addAuthorizedSender(sender);
        }
    }

    function riskOracle_removeAuthorizedSender(address sender)
        public
        getMsgSender
        checkExpectedErrors(RISK_ORACLE_OWNER_ERRORS)
    {
        sender = _getRandomAuthorizedSender(sender);

        vm.prank(msgSender);
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.removeAuthorizedSender, sender));

        if (success) {
            _removeAuthorizedSender(sender);
        }
    }

    function riskOracle_addUpdateType(string memory newUpdateType)
        public
        getMsgSender
        checkExpectedErrors(RISK_ORACLE_OWNER_ERRORS)
    {
        __before();

        vm.prank(msgSender);
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.addUpdateType, newUpdateType));

        if (success) {
            __after();
            riskOracle_validUpdateTypesKeyCount++;
            _addUpdateType(newUpdateType);
        }
    }

    function riskOracle_publishRiskParameterUpdate(
        string memory referenceId,
        bytes memory newValue,
        string memory updateType,
        address market,
        bytes memory additionalData
    ) public getMsgSender checkExpectedErrors(RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS) {
        __before();

        updateType = _getRandomUpdateType(updateType);
        vm.prank(msgSender);
        (success, returnData) = address(riskOracle).call(
            abi.encodeCall(
                riskOracle.publishRiskParameterUpdate, (referenceId, newValue, updateType, market, additionalData)
            )
        );

        if (success) {
            __after();
            riskOracle_updatesByIdKeyCount++;
        }
    }

    function riskOracle_publishBulkRiskParameterUpdates(
        string[] memory referenceIds,
        bytes[] memory newValues,
        string[] memory updateTypes,
        address[] memory markets,
        bytes[] memory additionalData
    ) public getMsgSender checkExpectedErrors(RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS) {
        __before();
        for (uint256 i = 0; i < updateTypes.length; i++) {
            updateTypes[i] = _getRandomUpdateType(updateTypes[i]);
        }
        vm.prank(msgSender);
        (success, returnData) = address(riskOracle).call(
            abi.encodeCall(
                riskOracle.publishBulkRiskParameterUpdates,
                (referenceIds, newValues, updateTypes, markets, additionalData)
            )
        );

        if (success) {
            __after();
            riskOracle_updatesByIdKeyCount += referenceIds.length;
        }
    }

    function riskOracle_getAllUpdateTypes() public checkExpectedErrors(RISK_ORACLE_GETTER_ERRORS) {
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.getAllUpdateTypes, ()));
    }

    function riskOracle_getLatestUpdateByParameterAndMarket(string memory updateType, address market)
        public
        checkExpectedErrors(RISK_ORACLE_GETTER_ERRORS)
    {
        updateType = _getRandomUpdateType(updateType);
        (success, returnData) = address(riskOracle).call(
            abi.encodeCall(riskOracle.getLatestUpdateByParameterAndMarket, (updateType, market))
        );
    }

    function riskOracle_isAuthorized(address sender) public checkExpectedErrors(EMPTY_ERRORS) {
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.isAuthorized, sender));
    }
}
