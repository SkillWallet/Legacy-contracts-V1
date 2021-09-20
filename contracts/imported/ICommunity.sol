//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/**
 * @title DistributedTown Community
 *
 * @dev Implementation of the Community concept in the scope of the DistributedTown project
 * @author DistributedTown
 */

interface ICommunity {
    event MemberAdded(
        address indexed _member,
        uint256 _skillWalletTokenId,
        uint256 _transferredTokens
    );
    event MemberLeft(address indexed _member);

    // check if it's called only from deployer.
    function joinNewMember(
        string memory uri,
        uint256 credits
    ) external;

    function getMembers() external view returns (uint256[] memory);
    
    function getMemberAddresses() external view returns (address[] memory);

    function getTokenId() external view returns (uint256);

    function getTemplate() external view returns (uint256);

    function getTreasuryBalance() external view returns (uint256);

    function getProjects() external view returns (uint256[] memory);

    function gigsAddr() external view returns (address);

    function isMember(address owner) external view returns (bool);

    function getProjectTreasuryAddress(uint256 projectId)
        external
        view
        returns (address);

    function balanceOf(address member) external view returns (uint256);

    function getSkillWalletAddress() external view returns(address);
}
