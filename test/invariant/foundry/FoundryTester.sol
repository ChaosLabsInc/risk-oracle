// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FoundryHandler} from "./FoundryHandler.sol";

import {PropertiesSpecifications} from "../PropertiesSpecifications.sol";
import {Test} from "forge-std/Test.sol";

contract FoundryTester is Test, PropertiesSpecifications {
    FoundryHandler public handler;

    function setUp() public {
        handler = new FoundryHandler();
        targetContract(address(handler));
    }

    function invariant() public {
        assertTrue(handler.invariant_no_duplicated_update_types());
        assertTrue(handler.invariant_valid_update_types_mapping_mirrors_all_update_types_array());
        assertTrue(handler.invariant_update_counter_should_equal_number_of_updates());
        assertTrue(handler.invariant_update_counter_is_monotonically_increasing());
    }
}
