// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {ExpectedErrors} from "./ExpectedErrors.sol";
import {Properties} from "./Properties.sol";
import {vm} from "@chimera/Hevm.sol";

import {RiskOracle} from "src/RiskOracle.sol";

abstract contract TargetFunctions is ExpectedErrors {
    function riskOracle_addAuthorizedSender(address sender)
        public
        getMsgSender
        checkExpectedErrors(RISK_ORACLE_OWNER_ERRORS)
    {
        vm.prank(msgSender);
        (success, returnData) =
            address(riskOracle).call(abi.encodeCall(riskOracle.addAuthorizedSender, _getRandomUser(sender)));
    }

    function riskOracle_removeAuthorizedSender(address sender)
        public
        getMsgSender
        checkExpectedErrors(RISK_ORACLE_OWNER_ERRORS)
    {
        vm.prank(msgSender);
        (success, returnData) =
            address(riskOracle).call(abi.encodeCall(riskOracle.removeAuthorizedSender, _getRandomUser(sender)));
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
        (success, returnData) = address(riskOracle).call(
            abi.encodeCall(riskOracle.getLatestUpdateByParameterAndMarket, (updateType, market))
        );
    }

    function riskOracle_getUpdateById(uint256 updateId) public checkExpectedErrors(RISK_ORACLE_GETTER_ERRORS) {
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.getUpdateById, updateId));

        if (success) {
            RiskOracle.RiskParameterUpdate memory update = abi.decode(returnData, (RiskOracle.RiskParameterUpdate));
            RiskOracle.RiskParameterUpdate[] memory updateHistory = riskOracle.exposed_updateHistory();
            t(_updatesEq(update, updateHistory[updateId - 1]), UPDATES_01);
        }
    }

    function riskOracle_isAuthorized(address sender) public checkExpectedErrors(EMPTY_ERRORS) {
        (success, returnData) = address(riskOracle).call(abi.encodeCall(riskOracle.isAuthorized, sender));
    }
}
