//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IOwnable.sol";

import "../../ISkillWallet.sol";
import "../interfaces/IPartnersAgreement.sol";
import "../../../imported/CommonTypes.sol";
import "../../community/ICommunity.sol";

import "@openzeppelin/contracts/token/ERC1155/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721Holder.sol";

contract PartnersAgreement is IPartnersAgreement, ERC721Holder, ERC1155Holder {
    event PartnersContractAdded(address _contract);

    event UrlAdded(string _url);

    uint256 public version;
    address public owner;

    address public override communityAddress;
    address[] public partnersContracts;
    string[] public urls;

    mapping(bytes32 => uint256) urlIds;

    uint256 public override rolesCount;

    ISkillWallet skillWallet;   
    address public activities;

    uint256 public override commitmentLevel;

    /**
     * @dev Throws PA not yet activated.
     */
    modifier onlyActive() {
        require(
            ICommunity(communityAddress).isMember(owner),
            "Owner hasn't joined the community yet!"
        );
        // require(
        //     ISkillWallet(skillWallet).isSkillWalletActivated(
        //         ISkillWallet(skillWallet).getSkillWalletIdByOwner(owner)
        //     ),
        //     "Owner hasn't activated their SW!"
        // );
        _;
    }

    modifier onlyCoreTeamMember() {
        require(
            ICommunity(communityAddress).isCoreTeamMember(msg.sender),
            "Not a core team member!"
        );
        _;
    }

    constructor(
        address skillWalletAddr,
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
        commitmentLevel = pa.commitmentLevel;
        skillWallet = ISkillWallet(skillWalletAddr);
    }

    function setActivities(address _activity) public {
        require(msg.sender == owner, "not owner");
        activities = _activity;
    }

    function addURL(string memory _url)
        public
        override
        onlyActive
        onlyCoreTeamMember
    {
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

        emit UrlAdded(_url);
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

    function getAllMembers() public view override returns (address[] memory) {
        return ICommunity(communityAddress).getMemberAddresses();
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

    function getImportedAddresses()
        public
        view
        override
        onlyActive
        returns (address[] memory)
    {
        return partnersContracts;
    }

    function getActivitiesAddress()
        public
        view
        override
        onlyActive
        returns (address)
    {
        return activities;
    }

    function getSkillWalletAddress() public view override returns (address) {
        return address(skillWallet);
    }

    function isActive() public view override returns (bool) {
        return
            ICommunity(communityAddress).isMember(owner); //&&
            // ISkillWallet(skillWallet).isSkillWalletActivated(
            //     ISkillWallet(skillWallet).getSkillWalletIdByOwner(owner)
            // );
    }

    // add core tema members array
    function getAgreementData()
        public
        view
        override
        returns (Types.PartnersAgreementData memory)
    {
        return
            Types.PartnersAgreementData(
                version,
                owner,
                communityAddress,
                partnersContracts,
                rolesCount,
                commitmentLevel
            );
    }
}
