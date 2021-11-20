//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./ISkillWallet.sol";
import "../imported/CommonTypes.sol";
import "./ISWActionExecutor.sol";
import "../imported/ICommunity.sol";
import "./OSM.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721MetadataUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title DistributedTown SkillWallet
 *
 * @dev Implementation of the SkillWallet contract
 * @author DistributedTown
 */
contract SkillWallet is
    ISkillWallet,
    IERC721MetadataUpgradeable,
    ERC721Upgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Mapping from token ID to active community that the SW is part of
    mapping(uint256 => address) private _activeCommunities;

    // Mapping from token ID to list of community addresses
    mapping(uint256 => address[]) private _communityHistory;

    // Mapping from skillWalletOwner to token ID
    mapping(address => uint256) private _skillWalletsByOwner;

    // Mapping from token ID to activated status
    mapping(uint256 => bool) private _activatedSkillWallets;

    mapping(uint256 => string) public skillWalletToPubKey;

    mapping(uint256 => string) public skillWalletToDiscordID;

    mapping(address => uint256) public skillWalletClaimers;

    CountersUpgradeable.Counter private _skillWalletCounter;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address public osmAddress;

    mapping(bytes32 => Types.SWValidationRequest)
        private clReqIdToValidationRequest;

    mapping(bytes32 => bool) validReqIds;

    function initialize(address _linkToken, address _oracle)
        public
        initializer
    {
        __Ownable_init();
        __ERC721_init("SkillWallet", "SW");

        _skillWalletCounter.increment();
        osmAddress = address(
            new OffchainSignatureMechanism(_linkToken, _oracle)
        );
    }

    function activateSkillWallet(uint256 skillWalletId) external override {
        require(
            msg.sender == osmAddress,
            "This function can be called only by the OSM contract!"
        );
        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );
        require(
            _activeCommunities[skillWalletId] != address(0),
            "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet."
        );
        require(
            _activatedSkillWallets[skillWalletId] == false,
            "SkillWallet: Skill wallet already activated"
        );
        _activatedSkillWallets[skillWalletId] = true;

        emit SkillWalletActivated(skillWalletId);
    }

    function addDiscordIDToSkillWallet(string calldata discordID)
        external
        override
    {
        uint256 skillWalletId = _skillWalletsByOwner[msg.sender];
        require(
            _activeCommunities[skillWalletId] != address(0),
            "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet."
        );
        require(
            _activatedSkillWallets[skillWalletId],
            "SkillWallet: Skill wallet not yet activated"
        );
        skillWalletToDiscordID[skillWalletId] = discordID;

        emit DiscordIDConnectedToSkillWallet(skillWalletId, discordID);
    }

    function claim() external override {
        require(
            balanceOf(msg.sender) == 0,
            "SkillWallet: There is SkillWallet already registered for this address."
        );

        require(
            skillWalletClaimers[msg.sender] > 0,
            "SkillWallet: There is no SkillWallet to be claimed by this address."
        );

        _transfer(address(this), msg.sender, skillWalletClaimers[msg.sender]);
        emit SkillWalletClaimed(skillWalletClaimers[msg.sender], msg.sender);
    }

    function create(
        address skillWalletOwner,
        string memory url,
        bool isClaimable
    ) external override {
        // TODO: Verify that the msg.sender is valid community
        require(
            balanceOf(skillWalletOwner) == 0,
            "SkillWallet: There is SkillWallet already registered for this address."
        );

        require(
            skillWalletClaimers[skillWalletOwner] == 0,
            "SkillWallet: There is SkillWallet to be claimed by this address."
        );

        uint256 tokenId = _skillWalletCounter.current();

        if (isClaimable) {
            _safeMint(address(this), tokenId);
            skillWalletClaimers[skillWalletOwner] = tokenId;
        } else {
            _safeMint(skillWalletOwner, tokenId);
        }

        _setTokenURI(tokenId, url);
        _activeCommunities[tokenId] = msg.sender;
        _communityHistory[tokenId].push(msg.sender);
        _skillWalletsByOwner[skillWalletOwner] = tokenId;
        _skillWalletCounter.increment();

        emit SkillWalletCreated(skillWalletOwner, msg.sender, tokenId);
    }

    function isRequestIdValid(bytes32 requestId)
        public
        view
        override
        returns (bool)
    {
        return validReqIds[requestId];
    }

    function addPubKeyToSkillWallet(
        uint256 skillWalletId,
        string calldata pubKey
    ) external override onlyOwner {
        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );
        require(
            _activeCommunities[skillWalletId] != address(0),
            "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet."
        );
        require(
            _activatedSkillWallets[skillWalletId] == false,
            "SkillWallet: Skill wallet already activated"
        );

        require(
            bytes(skillWalletToPubKey[skillWalletId]).length == 0,
            "SkillWallet: Skill wallet already has pubKey assigned."
        );

        require(
            ownerOf(skillWalletId) != address(this),
            "SkillWallet: Skill wallet hasn't been claimed yet."
        );
        skillWalletToPubKey[skillWalletId] = pubKey;

        emit PubKeyAddedToSkillWallet(skillWalletId);
    }

    /// ERC 721 overrides

    /// @notice ERC721 _transfer() Disabled
    /// @dev _transfer() has been overriden
    /// @dev reverts on transferFrom() and safeTransferFrom()
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(
            from == address(this),
            "SkillWallet: SkillWallet transfer disabled"
        );
        super._transfer(from, to, tokenId);
    }

    /// View Functions

    function isSkillWalletRegistered(address skillWalletOwner)
        external
        view
        override
        returns (bool status)
    {
        require(
            skillWalletOwner != address(0),
            "SkillWallet: Invalid skillWalletOwner address"
        );
        return balanceOf(skillWalletOwner) == 1;
    }

    function isSkillWalletClaimable(address skillWalletOwner)
        external
        view
        override
        returns (bool status)
    {
        require(
            skillWalletOwner != address(0),
            "SkillWallet: Invalid skillWalletOwner address"
        );
        return skillWalletClaimers[skillWalletOwner] > 0;
    }

    function isSkillWalletActivated(uint256 skillWalletId)
        external
        view
        override
        returns (bool status)
    {
        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );
        require(
            _activeCommunities[skillWalletId] != address(0),
            "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet."
        );

        return _activatedSkillWallets[skillWalletId];
    }

    function getCommunityHistory(uint256 skillWalletId)
        external
        view
        override
        returns (address[] memory communities)
    {
        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );
        require(
            _communityHistory[skillWalletId].length > 0,
            "SkillWallet: The SkillWallet is not part of any community."
        );
        return _communityHistory[skillWalletId];
    }

    function getActiveCommunity(uint256 skillWalletId)
        external
        view
        override
        returns (address community)
    {
        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );
        require(
            _activeCommunities[skillWalletId] != address(0),
            "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet."
        );
        return _activeCommunities[skillWalletId];
    }

    function getTotalSkillWalletsRegistered()
        external
        view
        override
        returns (uint256)
    {
        return _skillWalletCounter.current();
    }

    function getSkillWalletIdByOwner(address skillWalletOwner)
        external
        view
        override
        returns (uint256)
    {
        require(
            balanceOf(skillWalletOwner) == 1,
            "SkillWallet: The SkillWallet owner is invalid."
        );
        return _skillWalletsByOwner[skillWalletOwner];
    }

    function getPubKeyBySkillWalletId(uint256 skillWalletId)
        external
        view
        override
        returns (string memory)
    {
        return skillWalletToPubKey[skillWalletId];
    }

    function getClaimableSkillWalletId(address skillWalletOwner)
        external
        view
        override
        returns (uint256)
    {
        require(
            skillWalletClaimers[skillWalletOwner] > 0,
            "SkillWallet: The SkillWallet claimer is invalid."
        );
        return skillWalletClaimers[skillWalletOwner];
    }

    function getContractAddressPerAction(Types.Action action, address caller)
        public
        view
        override
        returns (address)
    {
        uint256 skillWalletId = _skillWalletsByOwner[caller];
        if (
            action == Types.Action.CreateGig ||
            action == Types.Action.TakeGig ||
            action == Types.Action.SubmitGig ||
            action == Types.Action.CompleteGig
        ) {
            address community = _activeCommunities[skillWalletId];
            address gigAddress = ICommunity(community).gigsAddr();
            return gigAddress;
        }
        return address(0);
    }

    function getOSMAddress() public view override returns (address) {
        return osmAddress;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
