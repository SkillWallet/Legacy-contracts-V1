
//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../imported/CommonTypes.sol";

interface ISkillWallet is IERC721 {

    event SkillWalletCreated(address indexed skillWalletOwner, address indexed community, uint256 indexed skillWalletId, Types.SkillSet skillSet);

    event SkillWalletActivated(uint256 indexed skillWalletId);
    event PubKeyAddedToSkillWallet(uint256 indexed skillWalletId);

    event SkillSetUpdated(uint256 indexed skillWalletId, Types.SkillSet newSkillSet);

    event SkillWalletCommunityChanged(uint256 indexed skillWalletId, address newCommunity);

    event ValidationPassed(uint256 tokenId, uint256 nonce, uint256 action);

    event ValidationFailed(uint256 tokenId, uint256 nonce, uint256 action);

    function create(address skillWalletOwner, Types.SkillSet memory skillSet, string memory url) external;

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) external;

    function activateSkillWallet(uint256 skillWalletId) external;
    
    function addPubKeyToSkillWallet(uint256 skillWalletId, string calldata pubKey) external;

    function isSkillWalletRegistered(address skillWalletOwner) external view returns (bool status);

    function getCommunityHistory(uint256 skillWalletId) external view returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId) external view returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

    function getSkillWalletIdByOwner(address skillWalletOwner) external view returns (uint256);

    function getSkillSet(uint256 skillWalletId) external view returns (Types.SkillSet memory skillSet);

    function isSkillWalletActivated(uint256 skillWalletId) external view returns (bool status);

    function isRequestIdValid(bytes32 requestId) external view returns (bool);

}