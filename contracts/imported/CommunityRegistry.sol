//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Community.sol";
import "./Membership.sol";

/**
 * @title DistributedTown CommunityRegistry
 *
 * @dev Implementation of the CommunityRegistry contract, which is a Factory and Registry of Communities
 * @author DistributedTown
 */
contract CommunityRegistry {
    event CommunityCreated(address _newCommunityAddress, address _membershipAddress);

    address[] public communities;
    uint256 public numOfCommunities;

    /**
     * @dev Creates a community
     * @return _communityAddress the newly created Community address
     **/
    function createCommunity(uint template) public returns (address _communityAddress) {
        Community community = new Community('', template);
        address newCommunityAddress = address(community);

        Membership membership = new Membership(newCommunityAddress);
        address newMembershipAddress = address(membership);

        communities[numOfCommunities] = newCommunityAddress;
        numOfCommunities = numOfCommunities + 1;

        emit CommunityCreated(newCommunityAddress, newMembershipAddress);

        return newCommunityAddress;
    }

}
