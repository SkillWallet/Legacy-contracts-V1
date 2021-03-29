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
     * @return _membershipAddress the newly created Membership address
     **/
    function createCommunity(uint template) public returns (address _communityAddress, address _membershipAddress) {
        Community community = new Community('', template);
        address newCommunityAddress = address(community);

        Membership membership = new Membership(newCommunityAddress);
        address newMembershipAddress = address(membership);

        community.setApprovalForMembership(newMembershipAddress);

        communities.push(CommunityData(newCommunityAddress, newMembershipAddress));
        numOfCommunities = numOfCommunities + 1;

        emit CommunityCreated(newCommunityAddress, newMembershipAddress);

        return (newCommunityAddress, newMembershipAddress);
    }

    // TODO: Probably we will rely only on events and don't need this
    /**
     * @dev Helper function for obtaining the community address and membership address by index of the community.
     * @param communityDataIndex - the index of the community in the communities array.
     * @return _communityAddress - community address
     * @return _membershipAddress - membership address
     **/
    function getCommunityData(uint256 communityDataIndex) public view returns (address _communityAddress, address _membershipAddress) {
        return (communities[communityDataIndex].community, communities[communityDataIndex].membership);
    }

}
