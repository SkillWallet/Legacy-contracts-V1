//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./ActivitiesOld.sol";

contract ActivitiesFactory {
    function deployActivities() public returns (address) {
        ActivitiesOld activities = new ActivitiesOld(msg.sender);

        return address(activities);
    }
}