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

    address private _partnerContractId;
    address private _partnerTokenId;
    uint8 private _tokenDistributionPercent;
    uint8 private _profitDistributionPercent;
    Template private _template;

    enum Template {OpenSource, Art, Local}

    constructor (address partnerContractId_, address partnerTokenId_, uint8 tokenDistributionPercent_, uint8 profitDistributionPercent_, uint8 template_) {
        // TODO: Add check to verify that the call is from the PartnerRegistry

        require(partnerContractId_ != address(0), "PartnerAgreement: partnerContractId_ cannot be the zero address.");
        require(partnerTokenId_ != address(0), "PartnerAgreement: partnerTokenId_ cannot be the zero address.");

        _partnerContractId = partnerContractId_;
        _partnerTokenId = partnerTokenId_;
        _tokenDistributionPercent = tokenDistributionPercent_;
        _profitDistributionPercent = profitDistributionPercent_;
        _template = Template(_template);
    }

    function getPartnerContractId() override external view returns(address) {
        return _partnerContractId;
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

}