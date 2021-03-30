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

    function createPartnerAgreement(address partnerContract, uint8 templateId, uint8[] memory skillIds) external returns(address partnerAgreement);

    function getPartnerAgreement(address creator) external view returns(address partnerAgreement);

}