//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

interface IActivitiesFactory {
    function deployActivities() external returns (address); 
}