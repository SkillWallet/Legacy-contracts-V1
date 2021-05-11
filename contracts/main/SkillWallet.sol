//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;
import "./ISkillWallet.sol";
import "../imported/CommonTypes.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.7/ChainlinkClient.sol";

/**
 * @title DistributedTown SkillWallet
 *
 * @dev Implementation of the SkillWallet contract
 * @author DistributedTown
 */
contract SkillWallet is
    ISkillWallet,
    IERC721Metadata,
    ERC721,
    Ownable,
    ChainlinkClient
{
    event ValidationPassed(string tokenId, uint256 nonce, uint256 action);
    event ValidationFailed(string tokenId, uint256 nonce, uint256 action);

    using Counters for Counters.Counter;

    // Mapping from token ID to active community that the SW is part of
    mapping(uint256 => address) private _activeCommunities;

    // Mapping from token ID to list of community addresses
    mapping(uint256 => address[]) private _communityHistory;

    // Mapping from token ID to SkillSet
    mapping(uint256 => Types.SkillSet) private _skillSets;

    // Mapping from skillWalletOwner to token ID
    mapping(address => uint256) private _skillWalletsByOwner;

    // Mapping from token ID to activated status
    mapping(uint256 => bool) private _activatedSkillWallets;

    mapping(uint256 => string) private _skillWalletToPubKey;

    Counters.Counter private _skillWalletCounter;

    // Chainlink params
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    constructor() public ERC721("SkillWallet", "SW") {
        setPublicChainlinkToken();

        // TODO: change with the ext adapter parameters
        oracle = 0xb5BA7f14Fe0205593255c77875348281b44DE7BF;
        jobId = "9fe037a36bdb44d1b4a5dec10a359893";

        fee = 0.1 * 10**18; // 0.1 LINK
    }

    function create(
        address skillWalletOwner,
        Types.SkillSet memory skillSet,
        string memory url
    ) external override {
        // TODO: Verify that the msg.sender is valid community
        require(
            balanceOf(skillWalletOwner) == 0,
            "SkillWallet: There is SkillWallet already registered for this address."
        );

        uint256 tokenId = _skillWalletCounter.current();

        _safeMint(skillWalletOwner, tokenId);
        _setTokenURI(tokenId, url);
        _activeCommunities[tokenId] = msg.sender;
        _communityHistory[tokenId].push(msg.sender);
        _skillSets[tokenId] = skillSet;
        _skillWalletsByOwner[skillWalletOwner] = tokenId;

        _skillWalletCounter.increment();

        emit SkillWalletCreated(
            skillWalletOwner,
            msg.sender,
            tokenId,
            skillSet
        );
    }

    function validate(
        string signature,
        uint256 tokenId,
        uint256 action,
        uint256 recoveryParam
    ) public {
        Chainlink.Request memory req =
            buildChainlinkRequest(
                jobId,
                address(this),
                this.validationCallback.selector
            );
        req.add("pubKey", _skillWalletToPubKey[tokenId]);
        req.add("signature", signature);
        req.add("action", action);
        req.add("recoveryParam", recoveryParam);
        req.add("tokenId", tokenId);
        req.add(
            "getNonceUrl",
            string(
                abi.encodePacked(
                    "https://api.distributed.town/api/skillwallet/",
                    tokenId,
                    "/nonces?action=",
                    action
                )
            )
        );
        req.add(
            "delNonceUrl",
            string(
                abi.encodePacked(
                    "https://api.distributed.town/api/skillwallet/",
                    tokenId,
                    "/nonces?action=",
                    action
                )
            )
        );

        sendChainlinkRequestTo(oracle, req, fee);
    }

    function validationCallback(bytes32 _requestId, bool _isValid)
        public
        recordChainlinkFulfillment(_requestId)
    {
        if (_isValid) emit ValidationPassed(0, 0, 0);
        else emit ValidationFailed(0,0,0);
    }

    function updateSkillSet(
        uint256 skillWalletId,
        Types.SkillSet memory newSkillSet
    ) external override {
        // TODO: Validate that the msg.sender is valid community

        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );

        _skillSets[skillWalletId] = newSkillSet;

        emit SkillSetUpdated(skillWalletId, newSkillSet);
    }

    function activateSkillWallet(uint256 skillWalletId, string pubKey)
        external
        override
        onlyOwner
    {
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

        _skillWalletToPubKey[skillWalletId] = pubKey;
        _activatedSkillWallets[skillWalletId] = true;

        emit SkillWalletActivated(skillWalletId);
    }

    function changeCommunity(uint256 skillWalletId) external override {
        // TODO: Validate that the msg.sender is valid community

        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );

        _activeCommunities[skillWalletId] = msg.sender;
        _communityHistory[skillWalletId].push(msg.sender);

        emit SkillWalletCommunityChanged(skillWalletId, msg.sender);
    }

    /// ERC 721 overrides

    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
    }

    /// @notice ERC721 _transfer() Disabled
    /// @dev _transfer() has been overriden
    /// @dev reverts on transferFrom() and safeTransferFrom()
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        require(false, "SkillWallet: SkillWallet transfer disabled");
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

    function getSkillSet(uint256 skillWalletId)
        external
        view
        override
        returns (Types.SkillSet memory skillSet)
    {
        require(
            skillWalletId < _skillWalletCounter.current(),
            "SkillWallet: skillWalletId out of range."
        );
        require(
            _activeCommunities[skillWalletId] != address(0),
            "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet."
        );

        return _skillSets[skillWalletId];
    }
}
