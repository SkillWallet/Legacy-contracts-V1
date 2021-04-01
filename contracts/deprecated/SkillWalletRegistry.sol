////SPDX-License-Identifier: MIT
//pragma solidity ^0.8.0;
//import "./ISkillWalletRegistry.sol";
//import "./SkillWallet.sol";
//import "../imported/Membership.sol";
//import "../imported/Community.sol";
//import "@openzeppelin/contracts/utils/Counters.sol";
//
///**
// * @title SkillWallet SkillWalletRegistry
// *
// * @dev Implementation of the SkillWalletRegistry contract, which is a Registry for SkillWallets
// * @author DistributedTown
// */
//contract SkillWalletRegistry is ISkillWalletRegistry {
//
//    using Counters for Counters.Counter;
//
//
//    event SkillWalletRegistered(address _skillWallet);
//
//    // Mapping to track skill wallet existence
//    mapping (address => bool) private _skillWallets;
//    Counters.Counter private _numWallets;
//
//    /**
//     * @dev Register an already created skill wallet
//     * @param skillWallet - The address of the SkillWallet
//     * @return status - The status of the operation
//     **/
//    function registerSkillWallet(SkillWallet skillWallet) override external returns (bool status) {
//
//        // TODO: Add check if the call is from the community or community registry that the SW is part of
//
//        address skillWalletAddress = address(skillWallet);
//        require(skillWalletAddress != address(0), "SkillWalletRegistry: SkillWallet cannot be registered for the zero address.");
//        require(_skillWallets[skillWalletAddress] == false, "SkillWalletRegistry: SkillWallet for the user already registered.");
//
//        _skillWallets[skillWalletAddress] = true;
//        _numWallets.increment();
//
//        emit SkillWalletRegistered(skillWalletAddress);
//        return true;
//    }
//
//    /**
//     * @dev Check if a specific SkillWallet is registered
//     * @param skillWallet - The address of the skillWallet
//     * @return status - Field representing wether the SkillWallet is registered or not
//     **/
//    function checkIfRegistered(address skillWallet) override external view returns (bool status) {
//        return _skillWallets[skillWallet];
//    }
//
//    /**
//     * @dev Get the total number of registered skill wallets
//     * @return count - The number of skill wallets registered
//     **/
//    function getTotalRegistered() override external view returns (uint256 count) {
//        return _numWallets.current();
//    }
//
//
//
//}