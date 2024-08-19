// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {PropertiesConstants} from "@crytic/util/PropertiesConstants.sol";
import {Setup} from "./Setup.sol";
import {Bounds} from "./Bounds.sol";

import {RiskOracle} from "src/RiskOracle.sol";

abstract contract Helper is Setup, Bounds {
    address internal msgSender;

    modifier getMsgSender() virtual {
        msgSender = msg.sender;
        _;
    }

    function _getRandomUser(address user) internal pure returns (address) {
        return uint160(user) % 3 == 0 ? USER1 : uint160(user) % 3 == 1 ? USER2 : USER3;
    }

    function _updatesEq(RiskOracle.RiskParameterUpdate memory update1, RiskOracle.RiskParameterUpdate memory update2)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encode(update1)) == keccak256(abi.encode(update2));
    }

    function _updateTypesEq(string memory updateType1, string memory updateType2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(updateType1)) == keccak256(abi.encodePacked(updateType2));
    }
}
