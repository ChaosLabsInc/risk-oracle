// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Properties} from "./Properties.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract ExpectedErrors is Properties {
    bool internal success;
    bytes internal returnData;

    bytes4[] internal RISK_ORACLE_OWNER_ERRORS;
    bytes4[] internal RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS;
    bytes4[] internal RISK_ORACLE_GETTER_ERRORS;
    bytes4[] internal EMPTY_ERRORS;

    constructor() {
        // RISK_ORACLE_OWNER_ERRORS
        RISK_ORACLE_OWNER_ERRORS.push(Ownable.OwnableUnauthorizedAccount.selector);
        RISK_ORACLE_OWNER_ERRORS.push(Ownable.OwnableInvalidOwner.selector);
        RISK_ORACLE_OWNER_ERRORS.push(bytes4(keccak256(bytes("Sender already authorized."))));
        RISK_ORACLE_OWNER_ERRORS.push(bytes4(keccak256(bytes("Sender not authorized."))));

        // RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS
        RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS.push(bytes4(keccak256(bytes("Unauthorized: Sender not authorized."))));
        RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS.push(bytes4(keccak256(bytes("Update type already exists."))));
        RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS.push(bytes4(keccak256(bytes("Unauthorized update type."))));
        RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS.push(bytes4(keccak256(bytes("Mismatch between argument array lengths."))));
        RISK_ORACLE_AUTHORIZED_UPDATE_ERRORS.push(bytes4(keccak256(bytes("Unauthorized update type at index"))));

        // RISK_ORACLE_GETTER_ERRORS
        RISK_ORACLE_GETTER_ERRORS.push(bytes4(keccak256(bytes("No updates found for the specified type."))));
        RISK_ORACLE_GETTER_ERRORS.push(
            bytes4(keccak256(bytes("No update found for the specified parameter and market.")))
        );
        RISK_ORACLE_GETTER_ERRORS.push(bytes4(keccak256(bytes("Invalid update ID."))));
    }

    modifier checkExpectedErrors(bytes4[] storage errors) {
        success = false;
        returnData = bytes("");

        _;

        if (!success) {
            bool expected = false;
            for (uint256 i = 0; i < errors.length; i++) {
                if (_checkReturnData(errors[i], returnData)) {
                    expected = true;
                    break;
                }
            }
            t(expected, DOS);
            precondition(false);
        }
    }

    function _checkReturnData(bytes4 errorSelector, bytes memory returndata) internal view returns (bool reverted) {
        if (returndata.length == 0) reverted = false;

        if (errorSelector == bytes4(returnData)) reverted = true;

        string memory errorString;
        assembly {
            // Get the length of the returndata
            let returndata_size := mload(returndata)

            // The first 32 bytes contain the length of the returndata
            let offset := add(returndata, 0x20)

            // The first 4 bytes of returndata after the length are the function selector (0x08c379a0 for Error(string))
            let selector := mload(offset)

            // Right shift the loaded value by 224 bits to keep only the first 4 bytes (function selector)
            selector := shr(224, selector)

            // Check that the selector matches the expected value for Error(string)
            if eq(selector, 0x08c379a0) {
                // The actual string data starts 32 bytes after the selector
                let stringOffset := add(offset, 0x20)

                // The length of the string is stored at stringOffset
                let stringLength := mload(stringOffset)

                // The actual string data starts 32 bytes after the string length
                let stringData := add(stringOffset, 0x20)

                // Set the length of the string in the allocated memory
                mstore(errorString, stringLength)

                // Copy the string data into the allocated memory
                let dest := add(errorString, 0x20) // point to where string data starts
                for { let i := 0 } lt(i, stringLength) { i := add(i, 0x20) } {
                    mstore(add(dest, i), mload(add(stringData, i)))
                }
            }
        }

        if (errorSelector == bytes4(keccak256(bytes(errorString)))) {
            reverted = true;
        }
    }
}
