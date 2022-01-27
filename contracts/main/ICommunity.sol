//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

/**
 * @title SkillWallet Community
 *
 * @dev Implementation of the Community concept in the scope of the SkillWallet project
 * @author SkillWallet
 */

interface ICommunity {
    event MemberAdded(address indexed _member, uint256 _skillWalletTokenId);
    event CoreTeamMemberAdded(address _member);


    enum STATUS {
        ACTIVE,
        IN_PROGRESS,
        MIGRATED
    }

    // check if it's called only from deployer.
    function joinNewMember(string memory uri, uint256 role) external;

    function getMembers() external view returns (uint256[] memory);

    function getMemberAddresses() external view returns (address[] memory);

    function getTemplate() external view returns (uint256);

    function getSkillWalletAddress() external view returns (address);

    function setMetadataUri(string calldata uri) external;

    function isMember(address member) external view returns (bool);

    function setPermissionBadgeAddress(address _permissionBadgeAddr) external;

    function isCoreTeamMember(address member) external view returns (bool);

    function coreTeamMembersCount() external view returns (uint256);

    function addNewCoreTeamMembers(address member) external;

    function getCoreTeamMembers() external view returns (address[] memory);

}
