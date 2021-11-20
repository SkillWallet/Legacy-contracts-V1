// SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "../imported/CommonTypes.sol";

interface ISkillWallet is IERC721Upgradeable, IERC721ReceiverUpgradeable {
    event SkillWalletCreated(
        address indexed skillWalletOwner,
        address indexed community,
        uint256 indexed skillWalletId
    );

    event SkillWalletActivated(uint256 indexed skillWalletId);

    event PubKeyAddedToSkillWallet(uint256 indexed skillWalletId);

    event SkillWalletCommunityChanged(
        uint256 indexed skillWalletId,
        address newCommunity
    );

    event SkillWalletClaimed(uint256 tokenId, address owner);

    event DiscordIDConnectedToSkillWallet(uint256 tokenId, string discordId);

    function create(
        address skillWalletOwner,
        string memory url,
        bool isClaimable
    ) external;

    function claim() external;
    
    function addDiscordIDToSkillWallet(string calldata discordID) external;

    function activateSkillWallet(uint256 skillWalletId) external;

    function addPubKeyToSkillWallet(
        uint256 skillWalletId,
        string calldata pubKey
    ) external;

    function isSkillWalletRegistered(address skillWalletOwner)
        external
        view
        returns (bool status);

    function isSkillWalletClaimable(address skillWalletOwner)
        external
        view
        returns (bool status);

    function getCommunityHistory(uint256 skillWalletId)
        external
        view
        returns (address[] memory communities);

    function getActiveCommunity(uint256 skillWalletId)
        external
        view
        returns (address community);

    function getTotalSkillWalletsRegistered() external view returns (uint256);

    function getSkillWalletIdByOwner(address skillWalletOwner)
        external
        view
        returns (uint256);

    function getClaimableSkillWalletId(address skillWalletOwner)
        external
        view
        returns (uint256);

    function getPubKeyBySkillWalletId(uint256 skillWalletId)
        external
        view
        returns (string memory);

    function getContractAddressPerAction(Types.Action action, address caller)
        external
        view
        returns (address);

    function isSkillWalletActivated(uint256 skillWalletId)
        external
        view
        returns (bool status);

    function isRequestIdValid(bytes32 requestId) external view returns (bool);

    function getOSMAddress()
        external
        view
        returns (address);
}
