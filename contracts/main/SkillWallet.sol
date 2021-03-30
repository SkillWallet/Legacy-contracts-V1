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

    Membership private _membership;
    address private _owner;


    constructor (address owner, Membership membership) {
        // TODO: Add check to verify that the call is from the SkillWalletRegistry
        _owner = owner;
        _membership = membership;
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