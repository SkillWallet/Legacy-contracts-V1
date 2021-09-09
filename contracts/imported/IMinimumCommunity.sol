//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/**
 * @title DistributedTown Community
 *
 * @dev Implementation of the Community concept in the scope of the DistributedTown project
 * @author DistributedTown
 */

interface IMinimumCommunity {
    event MemberAdded(
        address newMemberAddress,
        uint256 token,
        uint256 credits
    );

    function gigsAddr() external view returns (address);

    function getMembers() external view returns (uint256[] memory);

    function getTokenId() external view returns (uint256);

    function getTemplate() external view returns (uint256);

    function getTreasuryBalance() external view returns (uint256);

    function getProjects() external view returns (uint256[] memory);

    function getProjectTreasuryAddress(uint256 projectId)
        external
        view
        returns (address);

    function balanceOf(address member) external view returns (uint256);

    function joinNewMember(
        string memory uri,
        uint256 credits
    ) external;
}
