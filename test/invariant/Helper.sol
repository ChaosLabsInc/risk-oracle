// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Asserts} from "@chimera/Asserts.sol";
import {Bounds} from "./Bounds.sol";
import {Setup} from "./Setup.sol";

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {RiskOracle} from "src/RiskOracle.sol";

abstract contract Helper is Asserts, Bounds, Setup {
    using EnumerableSet for EnumerableSet.AddressSet;

    address internal msgSender;
    string[] internal updateTypes;
    EnumerableSet.AddressSet internal authorizedSenders;
    modifier getMsgSender() virtual {
        msgSender = msg.sender;
        _;
    }

    function _getRandomUser(address user) internal pure returns (address) {
        return uint160(user) % 3 == 0 ? USER1 : uint160(user) % 3 == 1 ? USER2 : USER3;
    }

    function _getRandomAuthorizedSender(address sender) internal returns (address) {
        if (authorizedSenders.length() == 0) {
            return _getRandomUser(sender);
        } else {
            return authorizedSenders.at(between(uint256(uint160(sender)), 0, authorizedSenders.length()));
        }
    }

    function _addAuthorizedSender(address sender) internal {
        authorizedSenders.add(sender);
    }

    function _removeAuthorizedSender(address sender) internal {
        authorizedSenders.remove(sender);
    }

    function _getRandomUpdateType(string memory updateType) internal returns (string memory) {
        if (updateTypes.length == 0) {
            return updateType;
        } else {
            return updateTypes[between(uint256(keccak256(abi.encodePacked(updateType))), 0, updateTypes.length)];
        }
    }

    function _addUpdateType(string memory updateType) internal {
        updateTypes.push(updateType);
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
