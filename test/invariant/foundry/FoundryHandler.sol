// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TargetFunctions} from "../TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";

contract FoundryHandler is TargetFunctions, FoundryAsserts {
    constructor() {
        vm.deal(address(USER1), 100e18);
        vm.deal(address(USER2), 100e18);
        vm.deal(address(USER3), 100e18);

        setup();
    }

    modifier getMsgSender() override {
        msgSender = uint160(msg.sender) % 3 == 0
            ? address(USER1)
            : uint160(msg.sender) % 3 == 1 ? address(USER2) : address(USER3);
        _;
    }
}
