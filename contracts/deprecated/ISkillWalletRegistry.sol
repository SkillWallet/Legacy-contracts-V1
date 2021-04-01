////SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
//import "./ISkillWallet.sol";
//import "../imported/Membership.sol";
//import "./SkillWallet.sol";
//
///**
// * @title SkillWallet ISkillWalletRegistry
// *
// * @dev Interface for the skill wallet registry contracts in the SkillWallet contract suite.
// * @author DistributedTown
// */
//interface ISkillWalletRegistry {
//
//    function registerSkillWallet(SkillWallet skillWallet) external returns (bool status);
//
//    function checkIfRegistered(address skillWallet) external view returns (bool status);
//
//    function getTotalRegistered() external view returns (uint256 count);
//
//}