//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../../utils/RoleUtils.sol";
import "../../ISkillWallet.sol";
import "./PartnersAgreement.sol";
import "../../community/ICommunity.sol";

contract Interactions {
    event MarkedAsInactive();

    struct InteractionModel {
        uint taskID;
        bool isActive;
    }

    address tasksAddress;
    address partnersAgreementAddress;
    mapping(uint => InteractionModel) interactions;
    mapping(address => uint256[]) interactionsPerUser;

    constructor(address pa) public {
        partnersAgreementAddress = pa;
    }

    function addInteractions(address to, uint256 taskID) public {
        
    }

    function getInteractionsCount(address user) public view returns (uint256) {
       return interactionsPerUser[user].length;
    }
}
