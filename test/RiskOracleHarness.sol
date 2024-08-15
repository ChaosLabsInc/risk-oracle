// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Ownable, RiskOracle} from "src/RiskOracle.sol";

function inArray(string memory element, string[] memory array) pure returns (bool) {
    for (uint256 i = 0; i < array.length; i++) {
        if (keccak256(abi.encodePacked(array[i])) == keccak256(abi.encodePacked(element))) {
            return true;
        }
    }
    return false;
}

contract RiskOracleHarness is RiskOracle {
    constructor(address[] memory initialSenders, string[] memory initialUpdateTypes)
        RiskOracle(initialSenders, initialUpdateTypes)
    {}

    function exposed_validUpdateTypes(string memory updateType) public view returns (bool) {
        return validUpdateTypes[updateType];
    }
}
