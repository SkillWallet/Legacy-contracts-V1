//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PartnerAgreement.sol";
import "./IPartnerAgreement.sol";
import "./IPartnerRegistry.sol";

/**
 * @title DistributedTown PartnerRegistry
 *
 * @dev Implementation of the PartnerRegistry contract, which is a Factory and Registry of Partner Agreements
 * @author DistributedTown
 */
contract PartnerRegistry is IPartnerRegistry {
    event PartnerAgreementCreated(address _partnerAgreement, address _creator);

    mapping(address => address) private _partnerAgreements;
    uint256 private _numOfAgreements;

    /**
     * @dev Creates a partner agreement
     * @param partnerContract - The address of the partner contract
     * @param templateId - The template of the community
     * @param skillIds - Array of the most frequent SkillIds
     * @return partnerAgreement the newly created PartnerAgreement instance
     **/
    function createPartnerAgreement(address partnerContract, uint8 templateId, uint8[] memory skillIds) external override returns(address partnerAgreement) {

        require(_partnerAgreements[msg.sender] == address(0), "PartnerRegistry: There is already partner agreement created for you.");

        require(partnerContract != address(0), "PartnerRegistry: partnerContract cannot be the zero address.");
        require(templateId <= 2, "PartnerRegistry: Invalid template ID.");
        require(skillIds.length == 2 || skillIds.length == 3, "PartnerRegistry: You need to provide between 2 and 3 skills.");

        PartnerAgreement _partnerAgreement = new PartnerAgreement(partnerContract, templateId, skillIds);
        address newPartnerAgreementAddress = address(_partnerAgreement);
        _partnerAgreements[msg.sender] = newPartnerAgreementAddress;
        _numOfAgreements = _numOfAgreements + 1;
        emit PartnerAgreementCreated(newPartnerAgreementAddress, msg.sender);
        return newPartnerAgreementAddress;
    }

    /**
     * @dev Get the PartnerAgreement for a specific user (creator)
     * @param creator - The address of the creator to get the PartnerAgreement for
     * @return partnerAgreement - The address of the PartnerAgreement for the specific user (creator)
     **/
    function getPartnerAgreement(address creator) external override view returns(address partnerAgreement) {
        require(_partnerAgreements[creator] != address(0), "PartnerRegistry: The partner agreement doesn't exists for the requested creator.");
        return _partnerAgreements[creator];
    }

}
