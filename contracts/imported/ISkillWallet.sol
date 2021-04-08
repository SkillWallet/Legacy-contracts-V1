
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./CommonTypes.sol";

interface ISkillWallet is IERC721 {

    event SkillWalletCreated(address indexed skillWalletOwner, address indexed community, uint256 indexed skillWalletId, Types.SkillSet skillSet);

    event SkillWalletActivated(uint256 indexed skillWalletId);

    event SkillSetUpdated(uint256 indexed skillWalletId, Types.SkillSet newSkillSet);

    event SkillWalletCommunityChanged(uint256 indexed skillWalletId, address newCommunity);

    function create(address skillWalletOwner, Types.SkillSet memory skillSet, string memory url) external;

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) external;

    function activateSkillWallet(uint256 skillWalletId) external;

    function changeCommunity(uint256 skillWalletId) external;

    function isSkillWalletRegistered(address skillWalletOwner) external view returns (bool status);

    function getCommunityHistory(uint256 skillWalletId) external view returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId) external view returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

    function getSkillWalletIdByOwner(address skillWalletOwner) external view returns (uint256);

    function getSkillSet(uint256 skillWalletId) external view returns (Types.SkillSet memory skillSet);

    function isSkillWalletActivated(uint256 skillWalletId) external view returns (bool status);

}