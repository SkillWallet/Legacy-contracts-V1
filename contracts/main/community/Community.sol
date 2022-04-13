//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "../ISkillWallet.sol";
import "./ICommunity.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title SkillWallet Community
 *
 * @dev Implementation of the Community concept in the scope of the SkillWallet project
 * @author SkillWallet
 */

contract Community is ICommunity {
    // upgradability
    uint256 public version;
    address public migratedFrom;
    address public migratedTo;

    // properties
    uint256 public template;
    string public metadataUri;
    address public override owner;

    address[] public memberAddresses;
    uint256[] public skillWalletIds;
    mapping(address => bool) public override isMember;

    uint16 public activeMembersCount;
    uint256 public totalMembersAllowed;

    mapping(address => bool) public override isCoreTeamMember;
    address[] coreTeamMemberWhitelist;

    uint256 public override coreTeamMembersCount;
    bool public isPermissioned;
    IERC721 permissionBadges;

    ISkillWallet public skillWallet;
    mapping(uint256 => uint256) public testMapping;

    modifier onlyCoreTeam() {
        require(
            isCoreTeamMember[msg.sender],
            "The signer is not whitelisted as core team member!"
        );
        require(
            skillWallet.balanceOf(msg.sender) > 0,
            "SkillWallet not created by the whitelisted member"
        );
        _;
    }

    constructor(
        address _owner,
        string memory _url,
        uint256 _template,
        uint256 _totalMembersAllowed,
        uint256 _coreTeamMembersCount,
        uint256 _version,
        address _skillWalletAddress,
        bool _isPermissioned,
        address _migrateFrom
    ) public {
        if (_migrateFrom == address(0)) {
            metadataUri = _url;
            totalMembersAllowed = _totalMembersAllowed;
            skillWallet = ISkillWallet(_skillWalletAddress);
            template = _template;
            owner = _owner;
            isPermissioned = _isPermissioned;
            coreTeamMembersCount = _coreTeamMembersCount;

            isCoreTeamMember[owner] = true;
            coreTeamMemberWhitelist.push(owner);
        } else {
            Community currentCommunity = Community(_migrateFrom);
            require(
                msg.sender == currentCommunity.owner(),
                "Only owner can migrate"
            );

            metadataUri = currentCommunity.metadataUri();
            totalMembersAllowed = currentCommunity.totalMembersAllowed();
            owner = currentCommunity.owner();
            template = currentCommunity.template();
            activeMembersCount = currentCommunity.activeMembersCount();

            address[] memory currentMembersAddresses = currentCommunity
                .getMemberAddresses();
            uint256[] memory currentSkillWalletIDs = currentCommunity
                .getMembers();
            for (uint256 i = 0; i < currentMembersAddresses.length; i++) {
                memberAddresses.push(currentMembersAddresses[i]);
                isMember[currentMembersAddresses[i]] = true;
            }
            for (uint256 i = 0; i < currentSkillWalletIDs.length; i++) {
                skillWalletIds.push(currentSkillWalletIDs[i]);
            }

            coreTeamMembersCount = currentCommunity.coreTeamMembersCount();
            address[] memory whitelist = currentCommunity.getCoreTeamMembers();
            for (uint256 i = 0; i < whitelist.length; i++) {
                isCoreTeamMember[whitelist[i]] = true;
                coreTeamMemberWhitelist.push(whitelist[i]);
            }

            skillWallet = ISkillWallet(
                currentCommunity.getSkillWalletAddress()
            );
            isPermissioned = currentCommunity.isPermissioned();

            migratedFrom = _migrateFrom;
        }
        version = _version;
    }

    function joinNewMember(string memory uri, uint256 role) public override {
        require(
            isCoreTeamMember[msg.sender] ||
                (!isPermissioned ||
                    (isPermissioned &&
                        address(permissionBadges) != address(0) &&
                        permissionBadges.balanceOf(msg.sender) > 0)),
            "The user has no permission badge."
        );
        require(
            activeMembersCount <= totalMembersAllowed,
            "No free spots left!"
        );
        require(!isMember[msg.sender], "Already a member");

        if (role >= 1 && role <= 3)
            require(
                activeMembersCount <=
                    totalMembersAllowed - coreTeamMembersCount,
                "No free spots for members roles"
            );

        if (role >= 4 && role <= 6)
            require(
                isCoreTeamMember[msg.sender],
                "User not whitelisted as core team member!"
            );

        skillWallet.create(msg.sender, uri, RoleUtils.Roles(role), false);

        uint256 token = skillWallet.getSkillWalletIdByOwner(msg.sender);

        memberAddresses.push(msg.sender);
        skillWalletIds.push(token);
        isMember[msg.sender] = true;
        activeMembersCount++;

        emit MemberAdded(msg.sender, token);
    }

    function setMetadataUri(string calldata uri) public override onlyCoreTeam {
        metadataUri = uri;
    }

    function setPermissionBadgeAddress(address _permissionBadgeAddr)
        public
        override
    {
        require(
            isPermissioned,
            "Non permissioned PAs can't have permissions badge address"
        );
        require(
            msg.sender == owner,
            "Only the owner can set permissions badge address!"
        );
        permissionBadges = IERC721(_permissionBadgeAddr);
    }

    function getSkillWalletAddress() public view override returns (address) {
        return address(skillWallet);
    }

    function getMembers() public view override returns (uint256[] memory) {
        return skillWalletIds;
    }

    function getMemberAddresses()
        public
        view
        override
        returns (address[] memory)
    {
        return memberAddresses;
    }

    function addNewCoreTeamMembers(address member)
        public
        override
        onlyCoreTeam
    {
        require(
            coreTeamMembersCount > coreTeamMemberWhitelist.length,
            "Core team member spots are filled."
        );
        require(!isCoreTeamMember[member], "Member already added");

        coreTeamMemberWhitelist.push(member);
        isCoreTeamMember[member] = true;

        emit CoreTeamMemberAdded(member);
    }

    function getCoreTeamMembers()
        public
        view
        override
        returns (address[] memory)
    {
        return coreTeamMemberWhitelist;
    }
}
