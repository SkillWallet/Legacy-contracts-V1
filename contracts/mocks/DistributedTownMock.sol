//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/**
 * @title IDistributedTown
 *
 * @dev DistributedTown Mock contract
 * @author DistributedTown
 */

contract DistributedTownMock {
    event CommunityCreated(
        address communityContract,
        uint256 communityId,
        uint256 template,
        address indexed creator
    );

    mapping (address => address) public ownerCommunities;
    address[] public communities;

    function addCommunity(address _owner, address _community) public {
        ownerCommunities[_owner] = _community;
    }

    function createCommunity(
        string calldata communityMetadata,
        uint256 template,
        uint totalMembersAllowed,
        address owner
    ) public {}

    function getCommunities() public view returns (address[] memory) {
        return communities;
    }

    function deployGenesisCommunities(uint256 template) public {}

    function getCommunityByOwner(address owner) public view returns(address) {
        return ownerCommunities[owner];
    }

    function setPartnersRegistryAddress(address partnersRegistry) public {}
}
