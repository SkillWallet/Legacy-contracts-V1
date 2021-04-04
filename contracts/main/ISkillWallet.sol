
//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../imported/CommonTypes.sol";

interface ISkillWallet is IERC721 {

    function create(address skillWalletOwner, Types.SkillSet memory skillSet, string memory url) external;

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) external;

    function activateSkillWallet(uint256 skillWalletId) external;

    function changeCommunity(uint256 skillWalletId) external;

    function isSkillWalletRegistered(address owner) external view returns (bool status);

    function getCommunityHistory(uint256 skillWalletId) external view returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId) external view returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

    function getSkillWalletIdByOwner(address owner) external view returns (uint256);

    function getSkillSet(uint256 skillWalletId) external view returns (Types.SkillSet memory skillSet);

    function isSkillWalletActivated(uint256 skillWalletId) external view returns (bool status);

}