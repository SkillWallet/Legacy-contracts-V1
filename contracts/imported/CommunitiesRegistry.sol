//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./Community.sol";
import "./Membership.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title DistributedTown CommunitiesRegistry
 *
 * @dev Implementation of the CommunitiesRegistry contract, which is a Factory and Registry of Communities
 * @author DistributedTown
 */
contract CommunitiesRegistry is ChainlinkClient, Ownable {
    event CommunityCreated(address indexed creator, address indexed community, address indexed membership, string name);

    using Strings for uint;

    mapping(address => bool) public isCommunity;
    address[] public communityAddresses;
    uint256 public numOfCommunities;
    address public skillWalletAddress;

    // Chainlink specific variables
    bytes32 private jobId;
    uint256 private fee;

    // Chainlink variable helpers
    address private _communityAddress;
    address private _userAddress;
    uint256 private _displayStringId1;
    uint256 private _level1;
    uint256 private _displayStringId2;
    uint256 private _level2;
    uint256 private _displayStringId3;
    uint256 private _level3;
    string private _uri;


    constructor(address _skillWalletAddress, address _link, address _oracle, bytes32 _jobId) public {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = 0.01 * 10 ** 18; // 0.1 LINK
        skillWalletAddress = _skillWalletAddress;
    }

    /**
     * @dev Creates a community
     * @return _communityAddress the newly created Community address
     **/
    function createCommunity(
        string memory _url,
        uint256 _ownerId,
        uint256 _ownerCredits,
        string memory _name,
        Types.Template _template,
        uint8 _positionalValue1,
        uint8 _positionalValue2,
        uint8 _positionalValue3
    ) external returns (address _communityAddress) {
        Community community =
        new Community(
            _url,
            _ownerId,
            _ownerCredits,
            _name,
            _template,
            _positionalValue1,
            _positionalValue2,
            _positionalValue3,
            skillWalletAddress,
            address(this)
        );
        address newCommunityAddress = address(community);

        isCommunity[newCommunityAddress] = true;
        communityAddresses.push(newCommunityAddress);
        numOfCommunities = numOfCommunities + 1;

        emit CommunityCreated(msg.sender, newCommunityAddress, address(community.getMembership()), community.name());

        return newCommunityAddress;
    }

    function joinNewMember(
        address community,
        address userAddress,
        uint256 displayStringId1,
        uint256 level1,
        uint256 displayStringId2,
        uint256 level2,
        uint256 displayStringId3,
        uint256 level3,
        string calldata uri
    ) external {
        require(isCommunity[community], "Invalid community address!");

        _userAddress = userAddress;
        _communityAddress = community;
        _displayStringId1 = displayStringId1;
        _level1 = level1;
        _displayStringId2 = displayStringId2;
        _level2 = level2;
        _displayStringId3 = displayStringId3;
        _level3 = level3;
        _uri = uri;

        _requestDitoCreditsCalculation(community, displayStringId1, level1, displayStringId2, level2, displayStringId3, level3);

    }

    function _requestDitoCreditsCalculation(address community, uint256 displayStringId1, uint256 level1, uint256 displayStringId2, uint256 level2, uint256 displayStringId3, uint256 level3) internal returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfillCalculateDitoCredits.selector);

        string memory url = "https://api.distributed.town/api/community/calculatecredits";
        // Set the URL to perform the GET request on
        request.add("get", url);

        request.add("queryParams", "commAddr=0x&skill1ID=1&skill2ID=2&skill3ID=3&lvl1=8&lvl2=9&lvl3=10");
//        request.add("queryParams", string(
//        abi.encodePacked(
//        "commAddr=",
//        community,
//        "&skill1ID=",
//        displayStringId1.toString(),
//        "&skill2ID=",
//        displayStringId2.toString(),
//        "&skill3ID=",
//        displayStringId3.toString(),
//        "&lvl1=",
//        level1.toString(),
//        "&lvl2=",
//        level2.toString(),
//        "&lvl3=",
//        level3.toString()
//        )));
        request.add("path", "credits");

        // Sends the request
        return sendChainlinkRequest(request, fee);
    }

    /**
     * @notice The fulfillCalculateDitoCredits method from requests created by this contract
     * @dev The recordChainlinkFulfillment protects this function from being called
     * by anyone other than the oracle address that the request was sent to
     * @param _requestId_ The ID that was generated for the request
     * @param _credits The answer provided by the oracle
     */
    function fulfillCalculateDitoCredits(bytes32 _requestId_, uint256 _credits)
    public
    recordChainlinkFulfillment(_requestId_)
    {
        _joinNewMember(_credits);
    }

    function _joinNewMember(uint256 credits) internal {
        Community communityContr = Community(_communityAddress);
        communityContr.joinNewMember(_userAddress, _displayStringId1, _level1, _displayStringId2, _level2, _displayStringId3, _level3, _uri, credits);
    }




    /**
 * @notice Allows the owner to withdraw any LINK balance on the contract
 */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(link.transfer(msg.sender, link.balanceOf(address(this))), "Unable to transfer");
    }

    /**
     * @notice Call this method if no response is received within 5 minutes
     * @param _requestId_ The ID that was generated for the request to cancel
     * @param _payment The payment specified for the request to cancel
     * @param _callbackFunctionId The bytes4 callback function ID specified for
     * the request to cancel
     * @param _expiration The expiration generated for the request to cancel
     */
    function cancelRequest(
        bytes32 _requestId_,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    )
    public
    onlyOwner
    {
        cancelChainlinkRequest(_requestId_, _payment, _callbackFunctionId, _expiration);
    }


    function joinExistingSW(
        address community,
        uint256 skillWalletTokenId,
        uint256 credits
    ) external {
        require(isCommunity[community], "Invalid community address!");

        Community communityContr = Community(community);
        communityContr.join(skillWalletTokenId, credits);
    }

    function getCommunities() public view returns(address[] memory) {
        return communityAddresses;
    }

    /**
     * @notice Returns the address of the LINK token
     * @dev This is the public implementation for chainlinkTokenAddress, which is
     * an internal method of the ChainlinkClient contract
     */
    function getChainlinkToken() public view returns (address) {
        return chainlinkTokenAddress();
    }
}
