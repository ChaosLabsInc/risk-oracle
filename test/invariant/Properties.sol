// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {BeforeAfter} from "./BeforeAfter.sol";
import {PropertiesSpecifications} from "./PropertiesSpecifications.sol";

import {RiskOracle} from "src/RiskOracle.sol";

// property tests get run after each call in a given sequence
abstract contract Properties is Asserts, BeforeAfter, PropertiesSpecifications {
    function invariant_no_duplicated_update_types() public returns (bool) {
        string[] memory allUpdateTypes = riskOracle.getAllUpdateTypes();
        for (uint256 i = 0; i < allUpdateTypes.length; i++) {
            for (uint256 j = i + 1; j < allUpdateTypes.length; j++) {
                t(!_updateTypesEq(allUpdateTypes[i], allUpdateTypes[j]), UPDATE_TYPES_01);
            }
        }

        return true;
    }

    function invariant_valid_update_types_mapping_mirrors_all_update_types_array() public returns (bool) {
        string[] memory allUpdateTypes = riskOracle.getAllUpdateTypes();
        eq(allUpdateTypes.length, riskOracle_validUpdateTypesKeyCount, UPDATE_TYPES_02);

        return true;
    }

    function invariant_update_counter_should_equal_number_of_updates() public returns (bool) {
        uint256 updateCounter = riskOracle.updateCounter();
        eq(updateCounter, riskOracle_updatesByIdKeyCount, UPDATE_COUNTER_02);

        return true;
    }

    function invariant_update_counter_is_monotonically_increasing() public returns (bool) {
        // riskOracle_updateCounter should be equal to _before.riskOracle_updateCounter, if a function was called in the
        // sequence that doesn't affect this state. Otherwise, the _after value should be at least equal to _before + 1
        // due to the updateCounter being incremented multiple times in the batch update call.
        t(_after.riskOracle_updateCounter >= _before.riskOracle_updateCounter, UPDATE_COUNTER_03);

        return true;
    }
}
