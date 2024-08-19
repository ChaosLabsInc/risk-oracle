// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {TargetFunctions} from "../TargetFunctions.sol";
import {FoundryAsserts} from "@chimera/FoundryAsserts.sol";
import "forge-std/console2.sol";

contract CryticToFoundry is Test, TargetFunctions, FoundryAsserts {
    function setUp() public {
        vm.deal(address(USER1), 100e18);
        vm.deal(address(USER2), 100e18);
        vm.deal(address(USER3), 100e18);

        // warp to initial Echidna timestamp and
        // roll to the corresponding block number
        vm.warp(1524785992);
        vm.roll(4370000);

        setup();

        msgSender = USER1;

        targetContract(address(riskOracle));
    }

    function _setUp(address _user, uint256 _time, uint256 _block) internal {
        msgSender = _user;
        vm.warp(block.timestamp + _time);
        vm.roll(block.number + _block);
    }

    function test_CryticToFoundry_01() public {
        // TODO: add failing property tests here for debugging

        _setUp(USER2, 314435 seconds, 29826);
    }
}
