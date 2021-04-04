//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./Membership.sol";
import "./CommunitiesRegistry.sol";
import "./CommonTypes.sol";
import "./ISkillWallet.sol";

/**
 * @title DistributedTown Community
 *
 * @dev Implementation of the Community concept in the scope of the DistributedTown project
 * @author DistributedTown
 */

contract Community is ERC1155, ERC1155Holder {
    address SKILL_WALLET_ADDRESS = address(0);
    address COMMUNITY_REGISTRY_ADDRESS = address(0);

    enum TokenType {DiToCredit, Community}

    Membership membership;
    ISkillWallet skillWallet;

    CommunitiesRegistry registry;

    string name;
    address communityCreator;
    uint16 activeMembersCount;
    mapping(uint256 => bool) activeSkillWallets;
    uint256 owner;

    /**
     * @dev emitted when a member is added
     * @param _member the user which just joined the community
     * @param _transferredTokens the amount of transferred dito tokens on join
     **/
    event MemberAdded(
        address _member,
        uint256 _skillWalletTokenId,
        uint256 _transferredTokens
    );
    event MemberLeft(address _member);

    // add JSON Schema base URL
    constructor(
        string memory _url,
        uint256 _ownerId,
        uint64 _ownerCredits,
        string memory _name,
        Types.Template _template,
        uint8 _positionalValue1,
        uint8 _positionalValue2,
        uint8 _positionalValue3,
        address skillWalletAddress,
        address communityRegistryAddress
    ) public ERC1155(_url) {
        skillWallet = ISkillWallet(skillWalletAddress);
        registry = CommunitiesRegistry(communityRegistryAddress);
        membership = new Membership(
            _template,
            _positionalValue1,
            _positionalValue2,
            _positionalValue3
        );
        name = _name;
        if (registry.numOfCommunities() == 0) {
            mintTokens();
        } else {
            // check if it's valid.
            // address ownerOfTheWallet = skillWallet.ownerOf(_ownerId);
            // if (ownerOfTheWallet != address(0)) {
            mintTokens();
            owner = _ownerId;
            join(_ownerId, _ownerCredits);
            // }
        }
    }

    function mintTokens() private {
        // Fungible DiToCredits ERC-20 token
        _mint(address(this), uint256(TokenType.DiToCredit), 96000 * 1e18, "");
        // Non-Fungible Community template NFT token
        _mint(address(this), uint256(TokenType.Community), 1, "");
    }

    function joinNewMember(
        Types.SkillSet calldata skillSet,
        string calldata uri,
        uint256 credits
    ) public {
        require(
            activeMembersCount <= 24,
            "There are already 24 members, sorry!"
        );

        skillWallet.create(msg.sender, skillSet, uri);

        uint256 tokenId = skillWallet.getSkillWalletIdByOwner(msg.sender);

        activeSkillWallets[tokenId] = true;
        activeMembersCount++;

        // get the skills from chainlink
        transferToMember(msg.sender, credits);
        emit MemberAdded(msg.sender, tokenId, credits);
    }

    function join(uint256 skillWalletTokenId, uint256 credits) public {
        require(
            activeMembersCount <= 24,
            "There are already 24 members, sorry!"
        );
        require(
            !activeSkillWallets[skillWalletTokenId],
            "You have already joined!"
        );

        address skillWalletAddress = skillWallet.ownerOf(skillWalletTokenId);

        require(
            msg.sender == skillWalletAddress,
            "Only the skill wallet owner can call this function"
        );

        activeSkillWallets[skillWalletTokenId] = true;
        activeMembersCount++;

        transferToMember(skillWalletAddress, credits);
        emit MemberAdded(skillWalletAddress, skillWalletTokenId, credits);
    }

    function leave(address memberAddress) public {
        emit MemberLeft(memberAddress);
    }

    function transferToMember(address _to, uint256 _value) public {
        super.safeTransferFrom(address(this), _to, 0, _value, "");
    }

    function transferToCommunity(address _from, uint256 _value) public {
        super.safeTransferFrom(_from, address(this), 0, _value, "");
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) public override {
        require(
            _id == uint256(TokenType.DiToCredit),
            "Community NFT can't be trasfered"
        );

        super.safeTransferFrom(_from, _to, _id, _value, _data);
    }

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) public override {
        require(
            !contains(_ids, uint256(TokenType.Community)),
            "Community NFT can't be trasfered"
        );

        super.safeBatchTransferFrom(_from, _to, _ids, _values, _data);
    }

    function balanceOf(address _owner, uint256 _id)
        public
        view
        override
        returns (uint256)
    {
        require(
            _id == uint256(TokenType.DiToCredit),
            "Community NFT doesn't have a balance."
        );
        super.balanceOf(_owner, _id);
    }

    function diToCreditsBalance(address _owner) public view returns (uint256) {
        super.balanceOf(_owner, uint256(TokenType.DiToCredit));
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        public
        view
        override
        returns (uint256[] memory)
    {
        require(
            !contains(_ids, uint256(TokenType.Community)),
            "Community NFT can't be trasfered"
        );

        super.balanceOfBatch(_owners, _ids);
    }

    function setApprovalForAll(address _operator, bool _approved)
        public
        override
    {
        super.setApprovalForAll(_operator, _approved);
    }

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        super.isApprovedForAll(_owner, _operator);
    }


    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, ERC1155Receiver) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
        || interfaceId == type(IERC1155MetadataURI).interfaceId
        || interfaceId == type(IERC1155Receiver).interfaceId
        || super.supportsInterface(interfaceId);
    }

    function getMembership() public returns (Membership) {
        return membership;
    }

    function contains(uint256[] memory arr, uint256 element)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == element) return true;
        }
        return false;
    }
}
