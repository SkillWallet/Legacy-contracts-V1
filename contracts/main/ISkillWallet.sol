
//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../imported/CommonTypes.sol";

interface ISkillWallet is IERC721, IERC721Receiver {

    event SkillWalletCreated(address indexed skillWalletOwner, address indexed community, uint256 indexed skillWalletId);

    event SkillWalletActivated(uint256 indexed skillWalletId);

    event PubKeyAddedToSkillWallet(uint256 indexed skillWalletId);

    event SkillWalletCommunityChanged(uint256 indexed skillWalletId, address newCommunity);

    event ValidationPassed(uint256 tokenId, uint256 nonce, uint256 action);

    event ValidationFailed(uint256 tokenId, uint256 nonce, uint256 action);

    event ValidationRequestIdSent(bytes32 requestId, address caller, uint256 tokenId);
    event SkillWalletClaimed(uint tokenId, address owner);

    function create(address skillWalletOwner, string memory url) external;

    function claim() external;

    function activateSkillWallet(uint256 skillWalletId) external;
    
    function addPubKeyToSkillWallet(uint256 skillWalletId, string calldata pubKey) external;

    function isSkillWalletRegistered(address skillWalletOwner) external view returns (bool status);
    
    function isSkillWalletClaimable(address skillWalletOwner) external view returns (bool status);

    function getCommunityHistory(uint256 skillWalletId) external view returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId) external view returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

    function getSkillWalletIdByOwner(address skillWalletOwner) external view returns (uint256);

    function getClaimableSkillWalletId(address skillWalletOwner) external view returns (uint256);

    function isSkillWalletActivated(uint256 skillWalletId) external view returns (bool status);

    function isRequestIdValid(bytes32 requestId) external view returns (bool);

}