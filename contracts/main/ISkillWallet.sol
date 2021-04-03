//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../imported/Types.sol";


interface ISkillWallet {

    function create(address owner, Types.SkillSet memory skillSet) external;

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) external;

    function changeCommunity(uint256 skillWalletId) external;

    function isSkillWalletRegistered(address owner) external view returns (bool status);

    function getCommunityHistory(uint256 skillWalletId) external view returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId) external view returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

    function getSkillWalletIdByOwner(address owner) external view returns (uint256);

}