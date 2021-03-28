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
contract PartnerRegistry {
    event PartnerAgreementCreated(address _partnerContractId, address _partnerTokenId);

    address[] public partnerAgreements;
    uint256 public numOfAgreements;

    /**
     * @dev Creates a partner agreement
     * @return partnerAgreement the newly created PartnerAgreement instance
     **/
    function createPartnerAgreement(address partnerContractId, address partnerTokenId, uint8 tokenDistributionPercent, uint8 profitDistributionPercent, uint8 template) external returns(IPartnerAgreement partnerAgreement) {
        PartnerAgreement _partnerAgreement = new PartnerAgreement(partnerContractId, partnerTokenId, tokenDistributionPercent, profitDistributionPercent, template);
        address newPartnerAgreementAddress = address(_partnerAgreement);
        partnerAgreements[numOfAgreements] = newPartnerAgreementAddress;

        numOfAgreements = numOfAgreements + 1;

        emit PartnerAgreementCreated(partnerContractId, partnerTokenId);

        return _partnerAgreement;
    }

}
