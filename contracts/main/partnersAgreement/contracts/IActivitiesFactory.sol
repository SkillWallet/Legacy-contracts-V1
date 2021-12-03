//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

interface IActivitiesFactory {
    function deployActivities(address _bot) external returns (address); 
}