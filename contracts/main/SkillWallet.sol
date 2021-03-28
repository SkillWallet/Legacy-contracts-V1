//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISkillWallet.sol";
import "../imported/Membership.sol";
import "../imported/Community.sol";
import "../utils/Types.sol";

/**
 * @title DistributedTown SkillWallet
 *
 * @dev Implementation of the SkillWallet contract
 * @author DistributedTown
 */
contract SkillWallet is ISkillWallet {

    // TODO: Change this to an array?
    Membership private _membership;
    address private _owner;


    constructor (address owner_, Membership membership_) {
        // TODO: Add check to verify that the call is from the SkillWalletRegistry

        require(owner_ != address(0), "SkillWallet: SkillWallet for the zero address can't be created.");
        require(address(membership_) != address(0), "SkillWallet: Membership must be valid.");
        require(membership_.isMember(owner_), "SkillWallet: The user is not a member.");

        _owner = owner_;
        _membership = membership_;
    }

    function getMembership() override external view returns(Membership) {
        return _membership;
    }

    function getOwner() override external view returns(address) {
        return _owner;
    }

    function getCommunity() override external view returns(Community) {
        return Community(_membership.communityAddress());
    }

    function getMemberInfo() override external view returns (Types.Member memory) {
        return _membership.getMember(_owner);
    }

}