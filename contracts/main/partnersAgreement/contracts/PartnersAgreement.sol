//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IPartnersAgreement.sol";
import "./InteractionNFT.sol";
import "../../../imported/ICommunity.sol";
import "../../ISkillWallet.sol";
import "../interfaces/IMembershipFactory.sol";

contract PartnersAgreement is IPartnersAgreement, ChainlinkClient {
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

    // Chainlink params
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address public override membershipAddress;

    /**
     * @dev Throws PA not yet activated.
     */
    modifier onlyActive() {
        require(isActive, "PA: not yet activated");
        _;
    }

    modifier onlyCoreTeamMember() {
        require(isCoreTeamMember[msg.sender], "The signer is not whitelisted as core team member!");
        require(skillWallet.balanceOf(msg.sender) > 0, "SkillWallet not created by the whitelisted member");
        _;
    }

    constructor(
        uint256 _version,
        address _partnersContract,
        address _owner,
        address _communityAddress,
        uint256 _rolesCount,
        uint256 _numberOfActions,
        uint256 _coreTeamMembers,
        address _oracle,
        address _chainlinkToken,
        address _membershipFactory,
        address _interactionsContract,
        address _membershipContract
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
        coreTeamMembersCount = _coreTeamMembers;

        skillWallet = ISkillWallet(ICommunity(communityAddress).getSkillWalletAddress());
        if (_interactionsContract == address(0)) {
            membershipAddress = IMembershipFactory(_membershipFactory)
                .createMembership(
                    ICommunity(communityAddress).getSkillWalletAddress(),
                    address(this)
                );

            partnersInteractionNFTContract = new InteractionNFT(
                _rolesCount,
                _numberOfActions
            );
        } else {
            partnersInteractionNFTContract = InteractionNFT(
                _interactionsContract
            );
            membershipAddress = _membershipContract;
        }

        setChainlinkToken(_chainlinkToken);
        oracle = _oracle;
        jobId = "e1e26fa27aa7436c95a78a40c21f5404";
        fee = 0.1 * 10**18; // 0.1 LINK
        isActive = false;
    }

    function activatePA() public override {
        require(!isActive, "PA already activated");
        bool isMember = ICommunity(communityAddress).isMember(owner);
        require(isMember, "Owner not yet a member of the community.");
        isActive = true;
        isCoreTeamMember[msg.sender] = true;
        coreTeamMemberWhitelist.push(msg.sender);
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

    function queryForNewInteractions(address userAddress)
        public
        override
        onlyActive
    {
        require(userAddress != address(0), "No user address passed!");

        for (uint256 i = 0; i < partnersContracts.length; i++) {
            Chainlink.Request memory req = buildChainlinkRequest(
                jobId,
                address(this),
                this.transferInteractionNFTs.selector
            );
            req.add("userAddress", string(abi.encodePacked(userAddress)));
            req.add(
                "contractAddress",
                string(abi.encodePacked(partnersContracts[i]))
            );
            req.add("chainId", "80001");
            req.addUint("startBlock", lastBlockPerUserAddress[userAddress]);
            req.add("covalentAPIKey", "ckey_aae01fa51e024af3a2634d9d030");

            bytes32 reqId = sendChainlinkRequestTo(oracle, req, fee);

            lastBlockPerUserAddress[userAddress] = block.number;
            userRequests[reqId] = userAddress;
        }
    }

    function transferInteractionNFTs(bytes32 _requestId, uint256 _result)
        public
        override
        onlyActive
        recordChainlinkFulfillment(_requestId)
    {
        address user = userRequests[_requestId];

        require(user != address(0), "req not found");
        ICommunity community = ICommunity(communityAddress);
        require(community.isMember(user), "Invalid user address");
        if (_result > 0) {
            partnersInteractionNFTContract.safeTransferFrom(
                address(this),
                user,
                uint(skillWallet.getRole(user)),
                _result,
                ""
            );
        }
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
        Ownable con = Ownable(contractAddress);
        require(
            con.owner() == msg.sender,
            "Only the owner of the contract can import it!"
        );
        partnersContracts.push(contractAddress);
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
            uint256,
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
            partnersInteractionNFTContract.getTotalSupplyAll(),
            coreTeamMembersCount
        );
    }
}
