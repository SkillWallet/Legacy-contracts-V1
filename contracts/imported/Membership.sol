//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Community.sol";
import "../utils/Types.sol";


/**
 * @title DistributedTown Membership contract
 *
 * @dev Implementation of the Membership contract in the scope of the DistributedTown project
 * @author DistributedTown
 */


contract Membership is Ownable {

    address public communityAddress;
    Community community;
    uint8 public numOfMembers;
    mapping(address => Types.Member) members;
    mapping(address => bool) public enabledMembers;


    /**
     * @dev emitted when a member is added
     * @param _member the user which just joined the community
     * @param _transferredTokens the amount of transferred dito tokens on join
     **/
    event MemberAdded(address _member, uint256 _transferredTokens);
    event MemberLeft(address _member);

    constructor(address _communityAddress) public {
        numOfMembers = 0;
        community = Community(_communityAddress);
        communityAddress = _communityAddress;
        // add treasury
    }

    function join(address memberAddress, Types.Member memory member)
    public
    {
        require(numOfMembers <= 24, "There are already 24 members, sorry!");
        require(
            !enabledMembers[memberAddress],
            "You have already joined!"
        );

        enabledMembers[memberAddress] = true;
        members[memberAddress] = member;
        numOfMembers++;
        uint16 credits = calculateCredits(memberAddress);
        community.transferDiToCredits(communityAddress, memberAddress, credits);
        emit MemberAdded(memberAddress, credits);
    }

    function leave(address memberAddress) public onlyOwner {
        // TODO: implement
        emit MemberLeft(memberAddress);
    }

    function calculateCredits(address memberAddress) internal view returns (uint16) {
        uint16 result = 2000;
        Types.Member memory member = members[memberAddress];

        // Ugly, research struct arrays in solidity :/
        result += member.skill1.value * member.skill1.level;
        result += member.skill2.value * member.skill2.level;
        result += member.skill3.value * member.skill3.level;
        return result;
    }

    function isMember(address member) public view returns (bool) {
        return enabledMembers[member];
    }


    function getMember(address member) external view returns (Types.Member memory) {
        require(enabledMembers[member], "Membership: The member doesn't exists");
        return members[member];
    }

    function contains(address[] memory arr, address element)
    internal
    pure
    returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == element) return true;
        }
        return false;
    }
}
