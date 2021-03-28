//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISkillWalletRegistry.sol";
import "./SkillWallet.sol";
import "../imported/Membership.sol";
import "../imported/Community.sol";

/**
 * @title DistributedTown SkillWalletRegistry
 *
 * @dev Implementation of the SkillWalletRegistry contract, which is a Factory and Registry for SkillWallets
 * @author DistributedTown
 */
contract SkillWalletRegistry is ISkillWalletRegistry {

    event SkillWalletCreated(address _owner, address _skillWallet);

    mapping (address => SkillWallet) private skillWallets;
    uint256 public numWallets;

    /**
     * @dev Creates a new instance of SkillWallet
     * @return skillWallet - The address of the newly created SkillWallet instance.
     **/
    function createSkillWallet(address owner, Membership membership) override external returns (ISkillWallet skillWallet) {
        require(owner != address(0), "SkillWalletRegistry: SkillWallet for the zero address can't be created.");
        require(address(skillWallets[owner]) == address(0), "SkillWalletRegistry: SkillWallet for the user already exists.");
        SkillWallet _skillWallet = new SkillWallet(owner, membership);

        skillWallets[owner] = _skillWallet;
        numWallets = numWallets + 1;

        emit SkillWalletCreated(owner, address(_skillWallet));
        return _skillWallet;
    }

    /**
     * @dev Get the SkillWallet for a specific user (owner)
     * @return skillWallet - The address of the SkillWallet for the specific user (owner)
     **/
    function getSkillWallet(address owner) override external view returns (ISkillWallet skillWallet) {
        require(address(skillWallets[owner]) != address(0), "SkillWalletRegistry: SkillWallet for the user doesn't exists.");
        return skillWallets[owner];
    }



}