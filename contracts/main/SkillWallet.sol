//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISkillWallet.sol";
import "../imported/CommonTypes.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/**
 * @title DistributedTown SkillWallet
 *
 * @dev Implementation of the SkillWallet contract
 * @author DistributedTown
 */
contract SkillWallet is ISkillWallet, ERC721 {

    using Counters for Counters.Counter;

    // Mapping from token ID to active community that the SW is part of
    mapping (uint256 => address) private _activeCommunities;

    // Mapping from token ID to list of community addresses
    mapping (uint256 => address[]) private _communityHistory;

    // Mapping from token ID to SkillSet
    mapping (uint256 => Types.SkillSet) private _skillSets;

    // Mapping from owner to token ID
    mapping (address => uint256) private _skillWalletsByOwner;

    // Mapping from token ID to SkillWallet metadata
    mapping (uint256 => string) private _urls;

    Counters.Counter private _skillWalletCounter;

    constructor () public ERC721("SkillWallet", "SW") {
    }

    function create(address owner, Types.SkillSet memory skillSet, string memory url) override external {

        // TODO: Verify that the msg.sender is valid community

        require(balanceOf(owner) == 0, "SkillWallet: There is SkillWallet already registered for this address.");

        uint256 tokenId = _skillWalletCounter.current();

        _safeMint(owner, tokenId);
        _activeCommunities[tokenId] = msg.sender;
        _communityHistory[tokenId].push(msg.sender);
        _skillSets[tokenId] = skillSet;
        _urls[tokenId] = url;
        _skillWalletsByOwner[owner] = tokenId;

        _skillWalletCounter.increment();

    }

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) override external {
        // TODO: Validate that the msg.sender is valid community

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");

        _skillSets[skillWalletId] = newSkillSet;
    }


    function changeCommunity(uint256 skillWalletId) override external {
        // TODO: Validate that the msg.sender is valid community

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");

        _activeCommunities[skillWalletId] = msg.sender;
        _communityHistory[skillWalletId].push(msg.sender);
    }

    /// ERC 721 overrides

    function _safeMint(address to, uint256 tokenId) internal override {
        super._safeMint(to, tokenId);
    }

    /// @notice ERC721 _transfer() Disabled
    /// @dev _transfer() has been overriden
    /// @dev reverts on transferFrom() and safeTransferFrom()
    function _transfer(address from, address to, uint256 tokenId) internal override {
        require(false, "SkillWallet: SkillWallet transfer disabled");
    }


    /// View Functions

    function isSkillWalletRegistered(address owner) override external view returns (bool status) {
        require(owner != address(0), "SkillWallet: Invalid SkillWallet owner address");
        return balanceOf(owner) == 1;
    }

    function getCommunityHistory(uint256 skillWalletId) override external view returns (address[] memory communities) {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_communityHistory[skillWalletId].length > 0, "SkillWallet: The SkillWallet is not part of any community.");
        return _communityHistory[skillWalletId];
    }

    function getActiveCommunity(uint256 skillWalletId) override external view returns (address community) {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_activeCommunities[skillWalletId] != address(0), "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet.");
        return _activeCommunities[skillWalletId];
    }

    function getTotalSkillWalletsRegistered() override external view returns (uint256) {
        return _skillWalletCounter.current();
    }

    function getSkillWalletIdByOwner(address owner) override external view returns (uint256) {
        require(balanceOf(owner) == 1, "SkillWallet: The SkillWallet owner is invalid.");
        return _skillWalletsByOwner[owner];
    }




}