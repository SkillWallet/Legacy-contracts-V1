//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Community.sol";
import "./Membership.sol";
import "../utils/Types.sol";

/**
 * @title DistributedTown CommunityRegistry
 *
 * @dev Implementation of the CommunityRegistry contract, which is a Factory and Registry of Communities
 * @author DistributedTown
 */
contract CommunityRegistry {
    event CommunityCreated(address _newCommunityAddress, address _membershipAddress);

    struct CommunityData {
        address community;
        address membership;
    }
    CommunityData[] public communities;
    uint256 public numOfCommunities;

    /**
     * @dev Creates a community
     * @return _communityAddress the newly created Community address
     **/
    function createCommunity(uint template) public returns (address _communityAddress, address _membershipAddress) {
        Community community = new Community('', template);
        address newCommunityAddress = address(community);

        Membership membership = new Membership(newCommunityAddress);
        address newMembershipAddress = address(membership);

        communities[numOfCommunities] = CommunityData(newCommunityAddress, newMembershipAddress);
        numOfCommunities = numOfCommunities + 1;

        emit CommunityCreated(newCommunityAddress, newMembershipAddress);

        return (newCommunityAddress, newMembershipAddress);
    }

    function joinCommunity(uint256 communityIndex, Types.Member memory member) external returns (bool status) {
        require(communityIndex < communities.length, "CommunityRegistry: CommunityIndex out of bounds.");

        // TODO: Add stronger require checks

        address membershipAddress = communities[communityIndex].membership;
        Membership membership = Membership(membershipAddress);
        membership.join(msg.sender, member);
        return true;
    }

}
