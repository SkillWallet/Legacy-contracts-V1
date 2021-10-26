//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/**
 * @title IDistributedTown
 *
 * @dev DistributedTown Interface
 * @author DistributedTown
 */

interface IDistributedTown {
    event CommunityCreated(
        address communityContract,
        uint256 communityId,
        uint256 template,
        address indexed creator
    );

    function createCommunity(
        string calldata communityMetadata,
        uint256 template,
        uint256 totalMembersAllowed,
        address owner
    ) external;

    function getCommunities() external view returns (address[] memory);

    function deployGenesisCommunities(uint256 template) external;

    function getCommunityByOwner(address owner) external view returns (address);

    function setPartnersRegistryAddress(address partnersRegistry) external;

    function projectsAddress()
        external
        view
        returns (address);
}
