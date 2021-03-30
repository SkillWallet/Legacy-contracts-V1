//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPartnerAgreement.sol";

/**
 * @title DistributedTown IPartnerAgreement
 *
 * @dev Interface for the partner agreement contracts in DistributedTown.
 * @author DistributedTown
 */
interface IPartnerAgreement {

    modifier onlyCreator() virtual;

    // Token distribution agreement
    function addTokenDistribution(address token, uint8 tokenDistributionPercent) external returns(bool);

    function updateToken(address newToken) external returns(bool);

    function updateTokenDistributionPercent(uint8 newTokenDistributionPercent) external returns(bool);

    // Profit sharing agreement
    function addProfitSharingDistribution(address treasury, uint8 profitSharingPercent) external returns(bool);

    function updateTreasury(address newTreasury) external returns(bool);

    function updateProfitSharingPercent(uint8 newProfitSharingPercent) external returns(bool);

    // Protocol contracts
    function addProtocolContract(address newProtocolContract) external returns (bool);

    function removeProtocolContract(address protocolContract) external returns (bool);

    // View functions
    function getToken() external view returns (address token);

    function getTreasury() external view returns (address treasury);

    function getTokenAgreement() external view returns (address token, uint8 tokenDistributionPercent);

    function getProfitSharingAgreement() external view returns (address treasury, uint8 profitSharingPercent);

    function getCreator() external view returns (address creator);

    function isProtocolContractAdded(address protocolContract) external view returns (bool);


}