//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISkillWallet.sol";
import "../imported/Membership.sol";

/**
 * @title DistributedTown ISkillWalletRegistry
 *
 * @dev Interface for the skill wallet registry contracts in DistributedTown.
 * @author DistributedTown
 */
interface ISkillWalletRegistry {

    function createSkillWallet(address owner, Membership membership) external returns(ISkillWallet);

    function getSkillWallet(address owner) external view returns (ISkillWallet);

}