//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./Activities.sol";

contract ActivitiesFactory {
    //for testing purposes, remove after integartion with pa
    address public lastDeployedAddress;

    function deployActivities(address _bot) public returns (address) {
        Activities activities = new Activities(msg.sender, _bot);
        
        //for testing purposes, remove after integartion with pa
        lastDeployedAddress = address(activities);

        return address(activities);
    }
}