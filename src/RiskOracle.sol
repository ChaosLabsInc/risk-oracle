// SPDX-License-Identifier: CC0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Dynamic Risk Oracle
 */
contract RiskOracle is Ownable {
    struct RiskParameterUpdate {
        uint256 timestamp; // Timestamp of the update
        bytes parameter; // Encoded parameters, flexible for various data types
        string referenceId; // External reference, potentially linking to a document or off-chain data
        bytes previousValue; // Previous value of the parameter for historical comparison
        string updateType; // Classification of the update for validation purposes
        uint256 updateId; // Unique identifier for this specific update˚˚˚˚
        bytes market; // Unique identifier for market of the parameter update
    }

    RiskParameterUpdate[] private updateHistory; // Stores all historical updates
    string[] private allUpdateTypes; // Array to store all update types
    mapping(string => bool) private validUpdateTypes; // Whitelist of valid update type identifiers
    mapping(uint256 => RiskParameterUpdate) private updatesById; // Mapping from unique update ID to the update details
    uint256 public updateCounter; // Counter to keep track of the total number of updates
    mapping(address => bool) private authorizedSenders; // Authorized accounts capable of executing updates

    event ParameterUpdated(
        string referenceId,
        bytes newValue,
        bytes previousValue,
        uint256 timestamls,
        string indexed updateType,
        uint256 indexed updateId,
        bytes indexed market
    );

    modifier onlyAuthorized() {
        require(
            authorizedSenders[msg.sender],
            "Unauthorized: Sender not authorized."
        );
        _;
    }

    /**
     * @notice Constructor to set initial authorized addresses and approved update types.
     * @param initialSenders List of addresses that will initially be authorized to perform updates.
     * @param initialUpdateTypes List of valid update types initially allowed.
     */
    constructor(
        address[] memory initialSenders,
        string[] memory initialUpdateTypes
    ) Ownable(msg.sender) {
        for (uint256 i = 0; i < initialSenders.length; i++) {
            authorizedSenders[initialSenders[i]] = true; // Automatically authorize initial senders
        }
        for (uint256 i = 0; i < initialUpdateTypes.length; i++) {
            validUpdateTypes[initialUpdateTypes[i]] = true; // Register initial valid updates
            allUpdateTypes.push(initialUpdateTypes[i]);
        }
        updateCounter = 0; // Initialize the update counter
    }

    /**
     * @notice Adds a new sender to the list of addresses authorized to perform updates.
     * @param sender Address to be authorized.
     */
    function addAuthorizedSender(address sender) external onlyOwner {
        require(!authorizedSenders[sender], "Sender already authorized.");
        authorizedSenders[sender] = true;
    }

    /**
     * @notice Removes an address from the list of authorized senders.
     * @param sender Address to be unauthorized.
     */
    function removeAuthorizedSender(address sender) external onlyOwner {
        require(authorizedSenders[sender], "Sender not authorized.");
        authorizedSenders[sender] = false;
    }

    /**
     * @notice Adds a new type of update to the list of authorized update types.
     * @param newUpdateType New type of update to allow.
     */
    function addUpdateType(string memory newUpdateType) external onlyOwner {
        require(
            !validUpdateTypes[newUpdateType],
            "Update type already exists."
        );
        validUpdateTypes[newUpdateType] = true;
        allUpdateTypes.push(newUpdateType);
    }

    /**
     * @notice Publishes a new risk parameter update.
     * @param referenceId An external reference ID associated with the update.
     * @param newValue The new value of the risk parameter being updated.
     * @param typeOfUpdate Type of update performed, must be previously authorized.
     */
    function publishRiskParameterUpdate(
        string memory referenceId,
        bytes memory newValue,
        string memory typeOfUpdate,
        bytes memory market
    ) external onlyAuthorized {
        require(validUpdateTypes[typeOfUpdate], "Unauthorized update type.");
        _processUpdate(referenceId, newValue, typeOfUpdate, market);
    }

    /**
     * @notice Publishes multiple risk parameter updates in a single transaction.
     * @param referenceIds Array of external reference IDs.
     * @param newValues Array of new values for each update.
     * @param typesOfUpdates Array of types for each update, all must be authorized.
     */
    function publishBulkRiskParameterUpdates(
        string[] memory referenceIds,
        bytes[] memory newValues,
        string[] memory typesOfUpdates,
        bytes[] memory markets
    ) external onlyAuthorized {
        require(
            referenceIds.length == newValues.length &&
                newValues.length == typesOfUpdates.length,
            "Mismatch between argument array lengths."
        );
        for (uint256 i = 0; i < referenceIds.length; i++) {
            require(
                validUpdateTypes[typesOfUpdates[i]],
                "Unauthorized update type at index"
            );
            _processUpdate(
                referenceIds[i],
                newValues[i],
                typesOfUpdates[i],
                markets[i]
            );
        }
    }

    /**
     * @dev Processes an update internally, recording and emitting an event.
     */
    function _processUpdate(
        string memory referenceId,
        bytes memory newValue,
        string memory typeOfUpdate,
        bytes memory market
    ) internal {
        updateCounter++;
        bytes memory previousValue = updateCounter > 0
            ? updatesById[updateCounter - 1].parameter
            : bytes("");
        RiskParameterUpdate memory newUpdate = RiskParameterUpdate(
            block.timestamp,
            newValue,
            referenceId,
            previousValue,
            typeOfUpdate,
            updateCounter,
            market
        );
        updatesById[updateCounter] = newUpdate;
        updateHistory.push(newUpdate);
        emit ParameterUpdated(
            referenceId,
            newValue,
            previousValue,
            block.timestamp,
            typeOfUpdate,
            updateCounter,
            market
        );
    }

    /**
     * @notice Fetches details about a specific update using its unique identifier.
     * @param updateId ID of the update to retrieve.
     * @return RiskParameterUpdate structure with all details of the update.
     */
    function fetchUpdateDetails(
        uint256 updateId
    ) external view returns (RiskParameterUpdate memory) {
        require(
            updateId > 0 && updateId <= updateCounter,
            "Invalid or non-existing update ID"
        );
        return updatesById[updateId];
    }

    /**
     * @notice Retrieves the most recent update for a given update type.
     * @param updateType The specific type of update to retrieve.
     * @return The most recent RiskParameterUpdate of the specified type.
     */
    function getLatestUpdateByType(
        string memory updateType
    ) external view returns (RiskParameterUpdate memory) {
        for (uint256 i = updateHistory.length; i > 0; i--) {
            if (Strings.equal(updateHistory[i - 1].updateType, updateType)) {
                return updateHistory[i - 1];
            }
        }
        revert("No updates found for the specified type.");
    }

    function getAllUpdateTypes() external view returns (string[] memory) {
        return allUpdateTypes;
    }

    /**
     * @notice Fetches the most recent update for a specific parameter in a specific market.
     * @param updateType The identifier for the parameter.
     * @param market The market identifier.
     * @return The most recent RiskParameterUpdate for the specified parameter and market.
     */
    function getLatestUpdateByParameterAndMarket(
        string memory updateType,
        bytes memory market
    ) external view returns (RiskParameterUpdate memory) {
        for (int256 i = int256(updateHistory.length) - 1; i >= 0; i--) {
            RiskParameterUpdate storage update = updateHistory[uint256(i)];
            if (
                keccak256(abi.encodePacked(update.updateType)) ==
                keccak256(abi.encodePacked(updateType)) &&
                keccak256(update.market) == keccak256(market)
            ) {
                return update;
            }
        }
        revert("No update found for the specified parameter and market.");
    }

    /*
     * @notice Fetches the update for a provided updateId.
     * @param updateId Update ID.
     * @return The most recent RiskParameterUpdate for the specified id.
     */
    function getUpdateById(
        uint256 updateId
    ) external view returns (RiskParameterUpdate memory) {
        require(
            updateId > 0 && updateId <= updateCounter,
            "Invalid update ID."
        );
        return updatesById[updateId];
    }

    /**
     * @notice Checks if an address is authorized to perform updates.
     * @param sender Address to check.
     * @return Boolean indicating whether the address is authorized.
     */
    function isAuthorized(address sender) external view returns (bool) {
        return authorizedSenders[sender];
    }
}
