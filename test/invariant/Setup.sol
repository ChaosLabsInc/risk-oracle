// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {BaseSetup} from "@chimera/BaseSetup.sol";
import {PropertiesConstants} from "@crytic/util/PropertiesConstants.sol";
import {vm} from "@chimera/Hevm.sol";

import "test/RiskOracleHarness.sol";

abstract contract Setup is BaseSetup, PropertiesConstants {
    RiskOracleHarness riskOracle;

    function setup() internal virtual override {
        address[] memory initialSenders = new address[](1);
        initialSenders[0] = USER1;
        string memory description;

        string[] memory initialUpdateTypes = new string[](1); // the corresponding ghost variable is initialized to 1
        initialUpdateTypes[0] = "InitialUpdateType";

        // deploy as USER1 so they become both the owner and an authorized sender
        vm.prank(USER1);
        riskOracle = new RiskOracleHarness(description, initialSenders, initialUpdateTypes);
    }
}
