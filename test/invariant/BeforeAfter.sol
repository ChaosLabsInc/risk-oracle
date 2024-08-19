// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Helper} from "./Helper.sol";

// ghost variables for tracking state variable values before and after function calls
abstract contract BeforeAfter is Helper {
    uint256 riskOracle_validUpdateTypesKeyCount = 1; // initialized to 1 because of the initial update type added in the setup
    uint256 riskOracle_updatesByIdKeyCount;

    struct Vars {
        uint256 riskOracle_updateCounter;
    }

    Vars internal _before;
    Vars internal _after;

    modifier clear() {
        Vars memory e;
        _before = e;
        _after = e;
        _;
    }

    function __snapshot(Vars storage vars) internal {
        vars.riskOracle_updateCounter = riskOracle.updateCounter();
    }

    function __before() internal {
        __snapshot(_before);

        // vm.recordLogs();
    }

    function __after() internal {
        // _parseLogs(vm.getRecordedLogs());

        __snapshot(_after);
    }

    // we can't use the logs method with the current version of HEVM because it's not implemented outside of Foundry –
    // refer here for more details https://github.com/crytic/properties/blob/main/README.md#hevm-cheat-codes-support
    // function _parseLogs(Vm.Log[] memory entries) internal {
    //     for (uint256 i = 0; i < entries.length; i++) {
    //         if (entries[i].emitter == address(riskOracle)) {
    //             if (entries[i].topics[0] == keccak256(RiskOracle.RiskParameterUpdate.selector)) {
    //                 riskOracle_updatesByIdKeyCount++;
    //             } else if (entries[i].topic == keccak256(RiskOracle.UpdateTypeAdded.selector)) {
    //                 riskOracle_validUpdateTypesKeyCount++;
    //             }
    //         }
    //     }
    // }
}
