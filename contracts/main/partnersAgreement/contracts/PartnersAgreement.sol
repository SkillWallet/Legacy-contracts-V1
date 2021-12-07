//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IOwnable.sol";

import "./InteractionNFT.sol";
import "../../../imported/ICommunity.sol";
import "../../ISkillWallet.sol";
import "../interfaces/IMembershipFactory.sol";
import "../../../imported/CommonTypes.sol";
import "./IActivities.sol";
import "./IActivitiesFactory.sol";
import "./IInteractionNFTFactory.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

contract PartnersAgreement is IPartnersAgreement, ERC721Holder {
    event CoreTeamMemberAdded (address _member);

    event PartnersContractAdded (address _contract);

    uint256 public version;
    address public owner;

    address public override communityAddress;
    address[] public partnersContracts;
    string[] public urls;

    mapping(bytes32 => uint256) urlIds;

    uint256 public override rolesCount;
    bool public override isActive;

    mapping(address => uint256) lastBlockPerUserAddress;
    mapping(bytes32 => address) userRequests;

    mapping(address => bool) public override isCoreTeamMember;
    address[] coreTeamMemberWhitelist;

    uint256 public override coreTeamMembersCount;

    InteractionNFT partnersInteractionNFTContract;
    ISkillWallet skillWallet;

    address public override membershipAddress;
    address interactionsQueryServer;
    IActivities public activities;


    /**
     * @dev Throws PA not yet activated.
     */
    modifier onlyActive() {
        require(isActive, "PA: not yet activated");
        _;
    }

    modifier onlyCoreTeamMember() {
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

    modifier onlyInteractionsQueryServer() {
        require(
            msg.sender == interactionsQueryServer,
            "Only interactions query server!"
        );
        _;
    }

    constructor(
        address _membershipFactory,
        address _interactionNFTFactory,
        Types.PartnersAgreementData memory pa
    ) public {
        require(
            pa.rolesCount == 2 || pa.rolesCount == 3,
            "Only 2 or 3 roles accepted"
        );
        version = pa.version;
        rolesCount = pa.rolesCount;
        owner = pa.owner;
        communityAddress = pa.communityAddress;
        coreTeamMembersCount = pa.coreTeamMembersCount;
        interactionsQueryServer = pa.interactionsQueryServer;

        for (uint256 i = 0; i < pa.partnersContracts.length; i++) {
            if(pa.partnersContracts[i] != address(0)) {
                if(pa.partnersContracts[i] != pa.communityAddress) {
                    require(
                            IOwnable(pa.partnersContracts[i]).owner() == pa.owner,
                            "Only the owner of the contract can import it!"
                    );
                }
                partnersContracts.push(pa.partnersContracts[i]);
            }
        }

        skillWallet = ISkillWallet(
            ICommunity(communityAddress).getSkillWalletAddress()
        );
        if (pa.interactionContract == address(0)) {
            membershipAddress = IMembershipFactory(_membershipFactory)
                .createMembership(
                    ICommunity(communityAddress).getSkillWalletAddress(),
                    address(this)
                );

            partnersInteractionNFTContract = InteractionNFT(
                IInteractionNFTFactory(_interactionNFTFactory).deployInteractionNFT(
                pa.rolesCount,
                pa.interactionsCount
            ));

            isActive = false;
        } else {
            partnersInteractionNFTContract = InteractionNFT(
                pa.interactionContract
            );

            coreTeamMemberWhitelist = pa.whitelistedTeamMembers;
            for (uint256 i = 0; i < pa.whitelistedTeamMembers.length; i++)
                isCoreTeamMember[pa.whitelistedTeamMembers[i]] = true;

            membershipAddress = pa.membershipContract;
            isActive = isCoreTeamMember[owner];
        }
    }

    function activatePA() override public {
        require(!isActive, "PA already activated");
        bool isMember = ICommunity(communityAddress).isMember(owner);
        require(isMember, "Owner not yet a member of the community.");
        isActive = true;
        isCoreTeamMember[msg.sender] = true;
        coreTeamMemberWhitelist.push(msg.sender);
    }

    function deployActivities(address _factory, address _bot) public {
        require(msg.sender == owner, "not owner");
        require(address(activities) == address(0), "already deployed");

        activities = IActivities(
            IActivitiesFactory(_factory).deployActivities(_bot)
        );
    }

    function createActivity(uint256 _type, string memory _uri)
        public
        onlyCoreTeamMember
    {
        if (_type == 1) {
            activities.createTask(_uri, msg.sender);
        } else {
            activities.createActivity(_type, _uri);
        }
    }

    function takeTask(uint256 _activityId) public onlyCoreTeamMember {
        activities.takeTask(_activityId, msg.sender);
    }

    function finilizeTask(uint256 _activityId) public onlyCoreTeamMember {
        activities.finilizeTask(_activityId, msg.sender);
    }

    function addURL(string memory _url) public override onlyActive onlyCoreTeamMember {
        require(msg.sender == owner, "not owner");

        bytes32 urlHash = keccak256(bytes(_url));
        bool exists = false;
        if (urls.length != 0) {
            if (urlIds[urlHash] != 0 || keccak256(bytes(urls[0])) == urlHash) {
                exists = true;
            }
        }
        require(!exists, "url already exists");

        urlIds[urlHash] = urls.length;
        urls.push(_url);
    }

    function removeURL(string memory _url)
        public
        override
        onlyActive
        onlyCoreTeamMember
    {
        require(msg.sender == owner, "not owner");
        require(isURLListed(_url), "url doesnt exist");

        bytes32 urlHash = keccak256(bytes(_url));
        uint256 urlId = urlIds[urlHash];

        if (urlId != urls.length - 1) {
            string memory lastUrl = urls[urls.length - 1];
            bytes32 lastUrlHash = keccak256(bytes(lastUrl));

            urlIds[lastUrlHash] = urlId;
            urls[urlId] = lastUrl;
        }

        urls.pop();
        delete urlIds[urlHash];
    }

    function getURLs() public view override returns (string[] memory) {
        return urls;
    }

    function isURLListed(string memory _url) public view override returns (bool) {
        if (urls.length == 0) return false;

        bytes32 urlHash = keccak256(bytes(_url));

        if (urlIds[urlHash] != 0) return true;
        if (keccak256(bytes(urls[0])) == urlHash) return true;

        return false;
    }

    function getInteractionNFTContractAddress()
        public
        view
        override
        onlyActive
        returns (address)
    {
        return address(partnersInteractionNFTContract);
    }

    function getAllMembers() public view onlyActive override returns (address[] memory) {
        ICommunity community = ICommunity(communityAddress);
        return community.getMemberAddresses();
    }

    function transferInteractionNFTs(address user, uint256 amountOfInteractions)
        public
        override
        onlyActive
        onlyInteractionsQueryServer
    {
        require(user != address(0), "Invalid user address");
        require(amountOfInteractions > 0, "Invalid amount of interactions");
        ICommunity community = ICommunity(communityAddress);
        require(community.isMember(user), "Invalid user address");
        partnersInteractionNFTContract.safeTransferFrom(
            address(this),
            user,
            uint256(skillWallet.getRole(user)),
            amountOfInteractions,
            ""
        );
    }

    function getInteractionNFT(address user)
        public
        view
        override
        onlyActive
        returns (uint256)
    {
        return partnersInteractionNFTContract.getActiveInteractions(user);
    }

    function addNewContractAddressToAgreement(address contractAddress)
        public
        override
        onlyActive
        onlyCoreTeamMember
    {
        IOwnable con = IOwnable(contractAddress);
        require(
            con.owner() == msg.sender,
            "Only the owner of the contract can import it!"
        );
        partnersContracts.push(contractAddress);

        emit PartnersContractAdded(contractAddress);
    }

    function addNewCoreTeamMembers(address member)
        public
        override
        onlyActive
        onlyCoreTeamMember
    {
        require(
            coreTeamMembersCount > coreTeamMemberWhitelist.length,
            "Core team member spots are filled."
        );
        coreTeamMemberWhitelist.push(member);
        isCoreTeamMember[member] = true;

        emit CoreTeamMemberAdded(member);
    }

    function getCoreTeamMembers()
        public
        view
        override
        onlyActive
        returns (address[] memory)
    {
        return coreTeamMemberWhitelist;
    }

    function getImportedAddresses()
        public
        view
        override
        onlyActive
        returns (address[] memory)
    {
        return partnersContracts;
    }

    // add core tema members array
    function getAgreementData()
        public
        override
        view
        returns (Types.PartnersAgreementData memory)
    {
        return
            Types.PartnersAgreementData(
                version,
                owner,
                communityAddress,
                partnersContracts,
                rolesCount,
                address(partnersInteractionNFTContract),
                membershipAddress,
                partnersInteractionNFTContract.getTotalSupplyAll(),
                coreTeamMembersCount,
                coreTeamMemberWhitelist,
                interactionsQueryServer
            );
    }
}
