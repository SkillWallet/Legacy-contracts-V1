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

    function getPartnerContract() external view returns (address);

    function getPartnerTokenId() external view returns (address);

    function getTokenAgreement() external view returns (uint8 tokenDistributionPercent, uint8 profitDistributionPercent);

    function getTemplate() external view returns (uint8);

    function getSkillIds() external view returns (uint8[] memory);

}