// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract PropertiesSpecifications {
    string internal constant UPDATE_TYPES_01 = "UPDATE_TYPES_01: allUpdateTypes should not contain any duplicates";
    string internal constant UPDATE_TYPES_02 =
        "UPDATE_TYPES_02: allUpdateTypes should be equal in length to the number of keys in validUpdateTypes";

    string internal constant UPDATES_01 = "UPDATES_01: updatesById[i] should equal updateHistory[i - 1]";

    string internal constant UPDATE_HISTORY_01 = "UPDATE_HISTORY_01: updateHistory should contain all updates";

    string internal constant UPDATE_COUNTER_01 =
        "UPDATE_COUNTER_01: updateCounter should equal the length of updateHistory";
    string internal constant UPDATE_COUNTER_02 =
        "UPDATE_COUNTER_02: updateCounter should be equal in length to the number of keys in updatesById";
    string internal constant UPDATE_COUNTER_03 = "UPDATE_COUNTER_03: updateCounter should be monotonically increasing";

    string internal constant DOS = "DOS: Denial of Service";

    string internal constant REVERTS = "REVERTS: Actions behave as expected under dependency reverts"; // TODO: relevant once contract has external dependencies
}
