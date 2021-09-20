//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./ISkillWallet.sol";
import "../imported/CommonTypes.sol";
import "./ISWActionExecutor.sol";
import "../imported/ICommunity.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

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

    mapping(uint256 => string) public skillWalletToPubKey;

    mapping(address => uint256) public skillWalletClaimers;

    Counters.Counter private _skillWalletCounter;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    mapping(bytes32 => Types.SWValidationRequest)
        private clReqIdToValidationRequest;

    mapping(bytes32 => bool) validReqIds;

    constructor(address _linkToken, address _oracle)
        public
        ERC721("SkillWallet", "SW")
    {
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = "31061086cb2749f7a3f99f2d5179caf7";
        fee = 0.1 * 10**18; // 0.1 LINK
        _skillWalletCounter.increment();
    }

    function activateSkillWallet(uint256 skillWalletId) external override {
        require(
            msg.sender == address(this),
            "This function can be called only by the SW contract!"
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

    function validate(
        string calldata signature,
        uint256 tokenId,
        uint256 action,
        string[] memory stringParams,
        uint256[] memory intParams,
        address[] memory addressParams
    ) public {
        require(
            bytes(skillWalletToPubKey[tokenId]).length > 0,
            "PubKey should be assigned to the skill walletID first!"
        );

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.validationCallback.selector
        );
        req.add("pubKey", skillWalletToPubKey[tokenId]);
        req.add("signature", signature);
        req.add(
            "getNonceUrl",
            string(
                abi.encodePacked(
                    "https://api.skillwallet.id/api/skillwallet/",
                    tokenId.toString(),
                    "/nonces?action=",
                    action.toString()
                )
            )
        );
        req.add(
            "delNonceUrl",
            string(
                abi.encodePacked(
                    "https://api.skillwallet.id/api/skillwallet/",
                    tokenId.toString(),
                    "/nonces?action=",
                    action.toString()
                )
            )
        );
        address caller = ownerOf(tokenId);
        bytes32 reqId = sendChainlinkRequestTo(oracle, req, fee);

        clReqIdToValidationRequest[reqId] = Types.SWValidationRequest(
            caller,
            Types.Action(action),
            Types.Params(stringParams, intParams, addressParams)
        );

        emit ValidationRequestIdSent(reqId, caller, tokenId);
    }

    function validationCallback(bytes32 _requestId, bool _isValid)
        public
        recordChainlinkFulfillment(_requestId)
    {
        // add a require here so that only the oracle contract can
        // call the fulfill alarm method
        Types.SWValidationRequest memory req = clReqIdToValidationRequest[
            _requestId
        ];
        if (_isValid) {
            emit ValidationPassed(0, 0, 0);
            validReqIds[_requestId] = true;

            if (req.action == Types.Action.Login) {
                return;
            } else if (req.action == Types.Action.Activate) {
                this.activateSkillWallet(_skillWalletsByOwner[req.caller]);
            } else {
                require(
                    this.isSkillWalletActivated(
                        _skillWalletsByOwner[req.caller]
                    ),
                    "SkillWallet must be activated first!"
                );

                ISWActionExecutor actionExecutor = ISWActionExecutor(
                    getContractAddressPerAction(req.action, req.caller)
                );

                actionExecutor.execute(
                    req.action,
                    req.caller,
                    req.params.intParams,
                    req.params.stringParams,
                    req.params.addressParams
                );
            }
        } else {
            emit ValidationFailed(0, 0, 0);
        }
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
        require(
            msg.sender != address(this),
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
        private
        view
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

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
