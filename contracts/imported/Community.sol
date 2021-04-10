//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./Membership.sol";
import "./CommunitiesRegistry.sol";
import "./CommonTypes.sol";
import "./ISkillWallet.sol";
import "./ERC1155.sol";

/**
 * @title DistributedTown Community
 *
 * @dev Implementation of the Community concept in the scope of the DistributedTown project
 * @author DistributedTown
 */

contract Community is ERC1155, ERC1155Holder {
    enum TokenType {DiToCredit, Community}

    Membership membership;
    ISkillWallet skillWallet;

    CommunitiesRegistry registry;

    string public name;
    uint256 public ownerId;
    uint16 public activeMembersCount;
    uint256 public scarcityScore;
    mapping(uint256 => bool) public isMember;
    uint256[] public skillWalletIds;


    // chainlink related variables
    address private _originalOwner;
    uint256 private _credits;

    /**
     * @dev emitted when a member is added
     * @param _member the user which just joined the community
     * @param _transferredTokens the amount of transferred dito tokens on join
     **/
    event MemberAdded(
        address indexed _member,
        uint256 _skillWalletTokenId,
        uint256 _transferredTokens
    );
    event MemberLeft(address indexed _member);

    // add JSON Schema base URL
    constructor(
        string memory _url,
        uint256 _ownerId,
        uint256 _ownerCredits,
        string memory _name,
        Types.Template _template,
        uint8 _positionalValue1,
        uint8 _positionalValue2,
        uint8 _positionalValue3,
        address skillWalletAddress,
        address communityRegistryAddress
    ) public ERC1155(_url, communityRegistryAddress) {
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
            mintTokens();
            ownerId = _ownerId;
            join(_ownerId, _ownerCredits);
        }
    }

    function mintTokens() internal {
        // Fungible DiToCredits ERC-20 token
        _mint(address(this), uint256(TokenType.DiToCredit), 96000 * 1e4, "");
        // Non-Fungible Community template NFT token
        _mint(address(this), uint256(TokenType.Community), 1, "");
    }

    // check if it's called only from deployer.
    function joinNewMember(
        address newMemberAddress,
        uint256 displayStringId1,
        uint256 level1,
        uint256 displayStringId2,
        uint256 level2,
        uint256 displayStringId3,
        uint256 level3,
        string calldata uri,
        uint256 credits
    ) public {
        require(
            activeMembersCount <= 24,
            "There are already 24 members, sorry!"
        );

        Types.SkillSet memory skillSet =
        Types.SkillSet(
            Types.Skill(displayStringId1, level1),
            Types.Skill(displayStringId2, level2),
            Types.Skill(displayStringId3, level3)
        );

        _credits = credits;
        _originalOwner = newMemberAddress;
        skillWallet.create(newMemberAddress, skillSet, uri);


        //        uint256 tokenId = skillWallet.getSkillWalletIdByOwner(newMemberAddress);

        //        isMember[tokenId] = true;
        //        skillWalletIds.push(tokenId);
        //        activeMembersCount++;
        //
        //        // get the skills from chainlink
        //        // transferToMember(newMemberAddress, credits);
        //        emit MemberAdded(newMemberAddress, tokenId, credits);
    }

    function join(uint256 skillWalletTokenId, uint256 credits) public {
        require(
            activeMembersCount <= 24,
            "There are already 24 members, sorry!"
        );
        require(!isMember[skillWalletTokenId], "You have already joined!");

        address skillWalletAddress = skillWallet.ownerOf(skillWalletTokenId);

        // require(
        //     msg.sender == skillWalletAddress,
        //     "Only the skill wallet owner can call this function"
        // );

        isMember[skillWalletTokenId] = true;
        skillWalletIds.push(skillWalletTokenId);
        activeMembersCount++;

        transferToMember(skillWalletAddress, credits);
        emit MemberAdded(skillWalletAddress, skillWalletTokenId, credits);
    }

    function leave(address memberAddress) public {
        emit MemberLeft(memberAddress);
    }

    function getSkillWalletIds()
    public
    view
    returns (uint256[] memory skillWalletIds)
    {
        return skillWalletIds;
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
    function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155, ERC165)
    returns (bool)
    {
        return
        interfaceId == type(IERC1155).interfaceId ||
        interfaceId == type(IERC1155MetadataURI).interfaceId ||
        // || interfaceId == type(IERC1155Receiver).interfaceId
        super.supportsInterface(interfaceId);
    }

    function getMembership() public view returns (Membership) {
        return membership;
    }

    function getTemplate() public view returns (Types.Template) {
        return membership.template();
    }

    function getPositionalValues() public view returns (uint16[3] memory) {
        uint16 p1 = membership.positionalValues(1);
        uint16 p2 = membership.positionalValues(2);
        uint16 p3 = membership.positionalValues(3);
        return [p1, p2, p3];
    }

    function contains(uint256[] memory arr, uint256 element)
    internal
    pure
    returns (bool)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == element) return true;
        }
        return false;
    }


    function skillWalletRegistered(uint256 tokenId, address owner) public  {
        // TODO: Add better validation

        require(_originalOwner != address(0), "Community: Invalid owner.");
        require(_originalOwner == owner, "Community: Invalid owner.");
        isMember[tokenId] = true;

        skillWalletIds.push(tokenId);
        activeMembersCount++;

        // get the skills from chainlink
        // transferToMember(newMemberAddress, credits);

        // reset variables
        _originalOwner = address(0);
        _credits = 0;
        emit MemberAdded(owner, tokenId, _credits);
    }

}

