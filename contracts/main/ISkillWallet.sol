//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../utils/Types.sol";


interface ISkillWallet {

    function create(bytes32 skillWalletHash, address community) external;

    function updateHash(uint256 skillWalletId, bytes32 newSkillWalletHash) external;

    function changeCommunity(uint256 skillWalletId, address newCommunityAddress) external;

    function isSkillWalletRegistered(address owner) external view returns (bool status);

    function getCommunityHistory(uint256 skillWalletId) external view returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId) external view returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

}