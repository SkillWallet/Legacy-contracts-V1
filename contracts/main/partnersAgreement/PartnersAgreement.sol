//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./InteractionNFT.sol";
import "../../imported/ICommunity.sol";

contract PartnersAgreement is ChainlinkClient {
    uint256 public version;
    address public owner;
    address public communityAddress;
    address[] public partnersContracts;
    //address supportedTokens;
    uint256 public rolesCount;
    bool public isActive;

    mapping(address => uint256) lastBlockPerUserAddress;
    mapping(bytes32 => address) userRequests;

    //TokenDistribution treasury;
    InteractionNFT partnersInteractionNFTContract;

    // Chainlink params
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;

    uint256 deploymentBlock;

    /**
     * @dev Throws PA not yet activated.
     */
    modifier onlyActive() {
        require(isActive, "PA: not yet activated");
        _;
    }

    constructor(
        uint256 _version,
        address _partnersContract,
        address _owner,
        address _communityAddress,
        uint256 _rolesCount,
        uint256 _numberOfActions,
        address _oracle,
        address _chainlinkToken,
        address _interactionsContract
    ) public {
        require(
            _rolesCount == 2 || _rolesCount == 3,
            "Only 2 or 3 roles accepted"
        );
        version = _version;
        rolesCount = _rolesCount;
        partnersContracts.push(_partnersContract);

        if(_interactionsContract == address(0)) {
            partnersInteractionNFTContract = new InteractionNFT(
                _rolesCount,
                _numberOfActions
            );
            owner = _owner;
            communityAddress = _communityAddress;
        } else {
            partnersInteractionNFTContract = InteractionNFT(_interactionsContract);
        }
        
        setChainlinkToken(_chainlinkToken);
        oracle = _oracle;
        jobId = "e1e26fa27aa7436c95a78a40c21f5404";
        fee = 0.1 * 10**18; // 0.1 LINK
        isActive = false;

        deploymentBlock = block.number;
    }

    function activatePA() public {
        require(!isActive, "PA already activated");
        bool isMember = ICommunity(communityAddress).isMember(owner);
        require(isMember, "Owner not yet a member of the community.");
        isActive = true;
    }

    function getInteractionNFTContractAddress()
        public
        view
        onlyActive
        returns (address)
    {
        return address(partnersInteractionNFTContract);
    }

    function getAllMembers() public view onlyActive returns (address[] memory) {
        ICommunity community = ICommunity(communityAddress);
        return community.getMemberAddresses();
    }

    function queryForNewInteractions(address userAddress) public {
        require(userAddress != address(0), "No user address passed!");

        for (uint256 i = 0; i < partnersContracts.length; i++) {
            Chainlink.Request memory req = buildChainlinkRequest(
                jobId,
                address(this),
                this.transferInteractionNFTs.selector
            );
            req.add("userAddress", addressToString(userAddress));
            req.add("contractAddress", addressToString(partnersContracts[i]));
            req.addUint("chainID", 80001);
            req.addUint("startBlock", lastBlockPerUserAddress[userAddress]);
            req.add("covalentAPIKey", "ckey_aae01fa51e024af3a2634d9d030");

            bytes32 reqId = sendChainlinkRequestTo(oracle, req, fee);

            lastBlockPerUserAddress[userAddress] = block.number;
            userRequests[reqId] = userAddress;
        }
    }

    function addressToString(address _address)
        private
        pure
        returns (string memory)
    {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = "0";
        _string[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            _string[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function transferInteractionNFTs(bytes32 _requestId, uint256 _result)
        public
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
                uint256(partnersInteractionNFTContract.userRoles(user)),
                _result,
                ""
            );
        }
    }

    function getInteractionNFT(address user)
        public
        view
        onlyActive
        returns (uint256)
    {
        return partnersInteractionNFTContract.getActiveInteractions(user);
    }

    function getUserRole(address _user)
        public
        view
        onlyActive
        returns (uint256)
    {
        return uint256(partnersInteractionNFTContract.userRoles(_user));
    }

    function addNewContractAddressToAgreement(address contractAddress)
        public
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
        onlyActive
        returns (address[] memory)
    {
        return partnersContracts;
    }

    function getAgreementData() public view onlyActive returns (
        uint256, 
        address, 
        address, 
        address[] memory, 
        uint256,
        address,
        uint256
    ) {
        return (
            version,
            owner,
            communityAddress,
            partnersContracts,
            rolesCount,
            address(partnersInteractionNFTContract),
            partnersInteractionNFTContract.getTotalSupplyAll()
        );
    }
}
