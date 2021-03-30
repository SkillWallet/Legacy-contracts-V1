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

    mapping (address => address) private skillWallets;
    uint256 public numWallets;

    /**
     * @dev Creates a new instance of SkillWallet
     * @param membership - The address of the membership contract that this user is part of
     * @return skillWallet - The address of the newly created SkillWallet instance.
     **/
    function createSkillWallet(Membership membership) override external returns (address skillWallet) {
        require(skillWallets[msg.sender] == address(0), "SkillWalletRegistry: SkillWallet for the user already exists.");

        require(address(membership) != address(0), "SkillWalletRegistry: The membership address cannot be the zero address.");
        require(membership.isMember(msg.sender), "SkillWalletRegistry: The user is not a member on the provided membership.");

        SkillWallet skillWallet = new SkillWallet(msg.sender, membership);
        address newSkillWalletAddress = address(skillWallet);

        skillWallets[msg.sender] = newSkillWalletAddress;
        numWallets = numWallets + 1;

        emit SkillWalletCreated(msg.sender, newSkillWalletAddress);
        return newSkillWalletAddress;
    }

    /**
     * @dev Get the SkillWallet for a specific user (owner)
     * @param owner - The address of the owner to get the SkillWallet for
     * @return skillWallet - The address of the SkillWallet for the specific user (owner)
     **/
    function getSkillWallet(address owner) override external view returns (address skillWallet) {
        require(address(skillWallets[owner]) != address(0), "SkillWalletRegistry: SkillWallet for the user doesn't exists.");
        return skillWallets[owner];
    }



}