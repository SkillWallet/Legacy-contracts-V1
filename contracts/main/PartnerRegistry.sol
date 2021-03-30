//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./PartnerAgreement.sol";
import "./IPartnerAgreement.sol";
import "./IPartnerRegistry.sol";
import "./SkillWallet.sol";

/**
 * @title DistributedTown PartnerRegistry
 *
 * @dev Implementation of the PartnerRegistry contract, which is a Factory and Registry of Partner Agreements
 * @author DistributedTown
 */
contract PartnerRegistry is IPartnerRegistry {
    event PartnerAgreementCreated(address _partnerAgreement, address _creator);

    // SkillWallet => PartnerAgreement mapping
    mapping(address => address) private _partnerAgreements;
    uint256 private _numOfAgreements;

    /**
     * @dev Creates a partner agreement
     * @param partnerContract - The address of the Partner protocol contract (one address is needed for the integration, the others can be added via updating the PartnerAgreement)
     * @param creator - The SkillWallet of the Partner protocol deployer
     * @return partnerAgreement - The address of the newly created PartnerAgreement contract
     **/
    function createPartnerAgreement(address partnerContract, SkillWallet creator) external override returns(address partnerAgreement) {
        // TODO: Verify that the skill wallet deployer is the partner contract deployer

        require(creator.getOwner() == msg.sender, "PartnerRegistry: Only the skillWallet owner can call this operation.");

        address creatorAddress = address(creator);

        require(_partnerAgreements[creatorAddress] == address(0), "PartnerRegistry: There is already partner agreement created for the skill wallet.");

        require(partnerContract != address(0), "PartnerRegistry: partnerContract cannot be the zero address.");

        PartnerAgreement _partnerAgreement = new PartnerAgreement(partnerContract, creator);

        address newPartnerAgreementAddress = address(_partnerAgreement);

        _partnerAgreements[creatorAddress] = newPartnerAgreementAddress;
        _numOfAgreements = _numOfAgreements + 1;

        emit PartnerAgreementCreated(newPartnerAgreementAddress, creatorAddress);
        return newPartnerAgreementAddress;
    }

    /**
     * @dev Get the PartnerAgreement for a specific SkillWallet
     * @param creator - The address of the SkillWallet to get the PartnerAgreement for
     * @return partnerAgreement - The address of the PartnerAgreement for the specific skillWallet
     **/
    function getPartnerAgreement(address creator) external override view returns(address partnerAgreement) {
        require(_partnerAgreements[creator] != address(0), "PartnerRegistry: The partner agreement doesn't exists for the requested creator.");
        return _partnerAgreements[creator];
    }


}
