//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./Activities.sol";

contract Interaction {
    event InteractionIndexIncreased(address member, uint256 total);
    using Counters for Counters.Counter;

    Counters.Counter private idCounter;

    struct InteractionModel {
        address member;
        uint256 taskID;
    }

    modifier onlyActivities() {
        require(
            msg.sender == activities,
            "Only Activities can call this function."
        );
        _;
    }

    mapping(uint256 => InteractionModel) interactions;
    mapping(address => uint256) interactionsIndex;

    address public activities;
    address public discordBotAddress;

    constructor() public {
        activities = msg.sender;
    }

    function addInteraction(uint256 activityID, address member)
        public
        onlyActivities
    {
        InteractionModel memory model = InteractionModel(member, activityID);

        idCounter.increment();
        interactions[idCounter.current()] = model;
        interactionsIndex[member]++;

        emit InteractionIndexIncreased(member, interactionsIndex[member]);
    }

    // view
    function getInteraction(uint256 interactionID)
        public
        view
        returns (InteractionModel memory)
    {
        return interactions[interactionID];
    }

    function getInteractionsIndexPerAddress(address user)
        public
        view
        returns (uint256)
    {
        return interactionsIndex[user];
    }
}
