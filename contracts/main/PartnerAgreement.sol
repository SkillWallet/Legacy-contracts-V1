//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../imported/Community.sol";
import "../utils/Types.sol";
import "./IPartnerAgreement.sol";
import "./SkillWallet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";


/**
 * @title DistributedTown PartnerAgreement
 *
 * @dev Implementation of the PartnerAgreement contract
 * @author DistributedTown
 */
contract PartnerAgreement is IPartnerAgreement {

    event TokenDistributionAgreementAdded(address _token, uint8 _tokenDistributionPercent);
    event ProfitSharingAgreementAdded(address _treasury, uint8 _profitSharingPercent);

    event TokenUpdated(address _newToken);
    event TokenDistributionPercentUpdated(uint8 _newTokenDistributionPercent);

    event TreasuryUpdated(address _newToken);
    event ProfitSharingPercentUpdated(uint8 _newProfitSharingPercent);

    event ProtocolContractAdded(address _newProtocolContract);
    event ProtocolContractRemoved(address _protocolContract);


    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _protocolContracts;
    SkillWallet private _creator;

    address private _token;
    address private _treasury;

    uint8 private _tokenDistributionPercent;
    uint8 private _profitSharingPercent;

    /**
     * @dev Throws if called by any account other than the SkillWallet owner.
     */
    modifier onlyCreator() override {
        require(_creator.getOwner() == msg.sender, "PartnerAgreement: caller is not the SkillWallet owner.");
        _;
    }


    constructor (address partnerContract, SkillWallet creator) {
        // TODO: Add check to verify that the call is from the PartnerRegistry
        _protocolContracts.add(partnerContract);
        _creator = creator;
    }


    // Token distribution agreement
    function addTokenDistribution(address token, uint8 tokenDistributionPercent) external override onlyCreator() returns(bool) {
        _token = token;
        _tokenDistributionPercent = tokenDistributionPercent;
        emit TokenDistributionAgreementAdded(token, tokenDistributionPercent);
        return true;
    }

    function updateToken(address newToken) external override onlyCreator() returns(bool) {
        _token = newToken;
        emit TokenUpdated(newToken);
        return true;
    }

    function updateTokenDistributionPercent(uint8 newTokenDistributionPercent) external override onlyCreator() returns(bool) {
        _tokenDistributionPercent = newTokenDistributionPercent;
        emit TokenDistributionPercentUpdated(newTokenDistributionPercent);
        return true;
    }

    // Profit sharing agreement
    function addProfitSharingDistribution(address treasury, uint8 profitSharingPercent) external override onlyCreator() returns(bool) {
        _treasury = treasury;
        _profitSharingPercent = profitSharingPercent;
        emit ProfitSharingAgreementAdded(treasury, profitSharingPercent);
        return true;
    }

    function updateTreasury(address newTreasury) external override onlyCreator() returns(bool) {
        _treasury = newTreasury;
        emit TreasuryUpdated(newTreasury);
        return true;
    }

    function updateProfitSharingPercent(uint8 newProfitSharingPercent) external override onlyCreator() returns(bool) {
        _profitSharingPercent = newProfitSharingPercent;
        emit ProfitSharingPercentUpdated(newProfitSharingPercent);
        return true;
    }

    // Protocol contracts
    function addProtocolContract(address newProtocolContract) external override onlyCreator() returns (bool) {
        // TODO: Verify deployer
        require(!_protocolContracts.contains(newProtocolContract), "PartnerAgreement: The newProtocolContract is already added.");
        _protocolContracts.add(newProtocolContract);
        emit ProtocolContractAdded(newProtocolContract);
        return true;
    }

    function removeProtocolContract(address protocolContract) external override onlyCreator() returns (bool) {
        // TODO: Verify deployer
        require(_protocolContracts.contains(protocolContract), "PartnerAgreement: The protocolContract is not added.");
        _protocolContracts.remove(protocolContract);
        emit ProtocolContractRemoved(protocolContract);
        return true;
    }


    function getToken() override external view returns (address token) {
        return _token;
    }

    function getTreasury() override external view returns (address treasury) {
        return _treasury;
    }

    function getTokenAgreement() override external view returns (address token, uint8 tokenDistributionPercent) {
        return (_token, _tokenDistributionPercent);
    }

    function getProfitSharingAgreement() override external view returns (address treasury, uint8 profitSharingPercent) {
        return (_treasury, _profitSharingPercent);
    }

    function getCreator() override external view returns(address creator) {
        return address(_creator);
    }

    function isProtocolContractAdded(address protocolContract) override external view returns (bool) {
        return _protocolContracts.contains(protocolContract);
    }

}