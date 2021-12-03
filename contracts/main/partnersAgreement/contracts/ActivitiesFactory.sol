//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./Activities.sol";

contract ActivitiesFactory {
    function deployActivities(address _bot) public returns (address) {
        Activities activities = new Activities(msg.sender, _bot);

        return address(activities);
    }
}