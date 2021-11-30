//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPartnersAgreement.sol";
import "./InteractionNFT.sol";
import "../../../imported/ICommunity.sol";
import "../interfaces/IMembershipFactory.sol";
import "../interfaces/IMembership.sol";

contract PartnersAgreement is IPartnersAgreement {
    uint256 public version;
    address public owner;
    address public override communityAddress;
    address[] public partnersContracts;
    string[] public urls;
    mapping(bytes32 => uint256) urlIds;
    //address supportedTokens;
    uint256 public override rolesCount;
    bool public override isActive;

    //TokenDistribution treasury;
    InteractionNFT partnersInteractionNFTContract;

    address public override membershipAddress;
    address interactionsQueryServer;

    /**
     * @dev Throws PA not yet activated.
     */
    modifier onlyActive() {
        require(isActive, "PA: not yet activated");
        _;
    }

    modifier onlyInteractionsNFTQueryServer() {
        require(
            msg.sender == interactionsQueryServer,
            "Only InteractionsQueryServer can call this."
        );
        _;
    }

    constructor(
        uint256 _version,
        address _partnersContract,
        address _owner,
        address _communityAddress,
        uint256 _rolesCount,
        uint256 _numberOfActions,
        address _membershipFactory,
        address _interactionsContract,
        address _membershipContract,
        address _interactionsQueryServer
    ) public {
        require(
            _rolesCount == 2 || _rolesCount == 3,
            "Only 2 or 3 roles accepted"
        );
        version = _version;
        rolesCount = _rolesCount;
        partnersContracts.push(_partnersContract);
        owner = _owner;
        communityAddress = _communityAddress;
        interactionsQueryServer = _interactionsQueryServer;
        if (_interactionsContract == address(0)) {
            membershipAddress = IMembershipFactory(_membershipFactory)
                .createMembership(
                    ICommunity(communityAddress).getSkillWalletAddress(),
                    address(this)
                );

            partnersInteractionNFTContract = new InteractionNFT(
                _rolesCount,
                _numberOfActions,
                membershipAddress
            );
        } else {
            partnersInteractionNFTContract = InteractionNFT(
                _interactionsContract
            );
            membershipAddress = _membershipContract;
        }

        isActive = false;
    }

    function activatePA() public override {
        require(!isActive, "PA already activated");
        bool isMember = ICommunity(communityAddress).isMember(owner);
        require(isMember, "Owner not yet a member of the community.");
        isActive = true;
    }

    function addURL(string memory _url) public override {
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

    function removeURL(string memory _url) public override {
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

    function isURLListed(string memory _url)
        public
        view
        override
        returns (bool)
    {
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

    function getAllMembers()
        public
        view
        override
        onlyActive
        returns (address[] memory)
    {
        ICommunity community = ICommunity(communityAddress);
        return community.getMemberAddresses();
    }

    function transferInteractionNFTs(address user, uint256 amountOfInteractions)
        public
        override
        onlyActive
        onlyInteractionsNFTQueryServer
    {
        require(user != address(0), "Invalid user address.");
        require(
            amountOfInteractions > 0,
            "Amount of interactions should be more than 0"
        );
        ICommunity community = ICommunity(communityAddress);
        require(community.isMember(user), "Invalid user address");
        partnersInteractionNFTContract.safeTransferFrom(
            address(this),
            user,
            IMembership(membershipAddress).getRole(user),
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
    {
        Ownable con = Ownable(contractAddress);
        require(
            con.owner() == msg.sender,
            "Only the owner of the contract can import it!"
        );
        partnersContracts.push(contractAddress);
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

    function getAgreementData()
        public
        view
        override
        onlyActive
        returns (
            uint256,
            address,
            address,
            address[] memory,
            uint256,
            address,
            address,
            uint256
        )
    {
        return (
            version,
            owner,
            communityAddress,
            partnersContracts,
            rolesCount,
            address(partnersInteractionNFTContract),
            membershipAddress,
            partnersInteractionNFTContract.getTotalSupplyAll()
        );
    }
}
