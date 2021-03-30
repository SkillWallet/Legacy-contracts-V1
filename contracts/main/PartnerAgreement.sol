//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../imported/Community.sol";
import "../utils/Types.sol";
import "./IPartnerAgreement.sol";


/**
 * @title DistributedTown PartnerAgreement
 *
 * @dev Implementation of the PartnerAgreement contract
 * @author DistributedTown
 */
contract PartnerAgreement is IPartnerAgreement {

    address private _partnerContract;
    address private _partnerTokenId;
    uint8 private _tokenDistributionPercent;
    uint8 private _profitDistributionPercent;
    Template private _template;
    uint8[] private _skillIds;

    enum Template {OpenSource, Art, Local}

    constructor (address partnerContract, uint8 templateId, uint8[] memory skillIds) {
        // TODO: Add check to verify that the call is from the PartnerRegistry
        _partnerContract = partnerContract;
        _template = Template(templateId);
        _skillIds = skillIds;
    }

    function getPartnerContract() override external view returns(address) {
        return _partnerContract;
    }

    function getPartnerTokenId() override external view returns(address) {
        return _partnerTokenId;
    }

    function getTokenAgreement() override external view returns(uint8 tokenDistributionPercent, uint8 profitDistributionPercent) {
        return (_tokenDistributionPercent, _profitDistributionPercent);
    }

    function getTemplate() override external view returns (uint8) {
        return uint8(_template);
    }

    function getSkillIds() override external view returns (uint8[] memory) {
        return _skillIds;
    }

}