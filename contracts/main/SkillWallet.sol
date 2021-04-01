//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ISkillWallet.sol";
import "../imported/Membership.sol";
import "../imported/Community.sol";
import "../utils/Types.sol";
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

    string private baseURI;

    // Mapping from token ID to active community that the SW is part of
    mapping (uint256 => address) private _activeCommunities;

    // Mapping from token ID to list of community addresses
    mapping (uint256 => address[]) private _communityHistory;

    // Mapping from token ID to skill wallet hash
    mapping (uint256 => bytes32) private _skillWalletHashes;

    Counters.Counter private _skillWalletCounter;

    constructor (string memory baseURI_) public ERC721("SkillWallet", "SW") {
        baseURI = baseURI_;
    }

    function create(bytes32 skillWalletHash, address community) override external {
        // TODO: Check if the msg.sender has joined the community
        // TODO: Validate the hash through Chainlink validator

        require(skillWalletHash != 0, "SkillWallet: Invalid skillWalletHash value");
        require(community != address(0), "SkillWallet: Invalid community address");

        require(balanceOf(msg.sender) == 0, "SkillWallet: There is SkillWallet already registered for this address.");

        uint256 tokenId = _skillWalletCounter.current();

        _skillWalletHashes[tokenId] = skillWalletHash;
        _activeCommunities[tokenId] = community;
        _communityHistory[tokenId].push(community);
        _safeMint(msg.sender, tokenId);

        _skillWalletCounter.increment();

    }

    function updateHash(uint256 skillWalletId, bytes32 newSkillWalletHash) override external {
        // TODO: Validate the hash through Chainlink validator

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(newSkillWalletHash != 0, "SkillWallet: Invalid newSkillWalletHash value.");

        require(ownerOf(skillWalletId) == msg.sender, "SkillWallet: Only the SkillWallet owner can call this operation.");

        _skillWalletHashes[skillWalletId] = newSkillWalletHash;
    }


    function changeCommunity(uint256 skillWalletId, address newCommunityAddress) override external {
        // TODO: Validate that the msg.sender has joined the new community

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(newCommunityAddress != address(0), "SkillWallet: Invalid newCommunityAddress value.");

        require(ownerOf(skillWalletId) == msg.sender, "SkillWallet: Only the SkillWallet owner can call this operation.");

        _activeCommunities[skillWalletId] = newCommunityAddress;
        _communityHistory[skillWalletId].push(newCommunityAddress);
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

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }


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



}