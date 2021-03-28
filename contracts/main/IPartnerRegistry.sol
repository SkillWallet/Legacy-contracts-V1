//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPartnerAgreement.sol";

/**
 * @title DistributedTown IPartnerRegistry
 *
 * @dev Interface for the partner registry contracts in DistributedTown.
 * @author DistributedTown
 */
interface IPartnerRegistry {

    function createPartnerAgreement(address partnerContractId, address partnerTokenId, uint8 tokenDistributionPercent, uint8 profitDistributionPercent, uint8 template) external returns(IPartnerAgreement partnerAgreement);

}