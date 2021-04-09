//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
//import "./ISkillWallet.sol";
import "../imported/CommonTypes.sol";
import "../imported/Community.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";

/**
 * @title DistributedTown SkillWallet
 *
 * @dev Implementation of the SkillWallet contract
 * @author DistributedTown
 */
contract SkillWallet is ChainlinkClient, ISkillWallet, ERC721, Ownable {

    using Counters for Counters.Counter;

    // Mapping from token ID to active community that the SW is part of
    mapping (uint256 => address) private _activeCommunities;

    // Mapping from token ID to list of community addresses
    mapping (uint256 => address[]) private _communityHistory;

    // Mapping from token ID to SkillSet
    mapping (uint256 => Types.SkillSet) private _skillSets;

    // Mapping from skillWalletOwner to token ID
    mapping (address => uint256) private _skillWalletsByOwner;

    // Mapping from token ID to activated status
    mapping (uint256 => bool) private _activatedSkillWallets;

    // Mapping from token ID to SkillWallet metadata
    mapping (uint256 => string) private _urls;

    // Mapping from skillWalletOwner to random string used for the QR code verification
    mapping (address => string) private _randomStrings;

    Counters.Counter private _skillWalletCounter;

    // Chainlink specific variables
    bytes32 private jobId;
    uint256 private fee;

    // Chainlink helper variables, used for the data capturing before the chainlink request
    address private _skillWalletOwner;
    address private _community;
    Types.SkillSet private _skillSet;
    string private _url;


    /**
     * @notice Deploy the contract with a specified address for the LINK token, oracle address and jobId
     * @dev Sets the storage for the specified addresses and jobId
     * @param _link The address of the LINK token contract
     * @param _oracle The address of the Chainlink oracle
     * @param _jobId The id of the Chainlink job
     */
    constructor (address _link, address _oracle, bytes32 _jobId) public ERC721("SkillWallet", "SW") {
        if (_link == address(0)) {
            setPublicChainlinkToken();
        } else {
            setChainlinkToken(_link);
        }
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = 0.01 * 10 ** 18; // 0.01 LINK
    }

    function create(address skillWalletOwner, Types.SkillSet memory skillSet, string memory url) override external {

        // TODO: Verify that the msg.sender is valid community

        require(balanceOf(skillWalletOwner) == 0, "SkillWallet: There is SkillWallet already registered for this address.");
        require(_skillWalletOwner == address(0), "SkillWallet: Request in progress, please try again later.");

        _skillWalletOwner = skillWalletOwner;
        _skillSet = skillSet;
        _url = url;
        _community = msg.sender;

        _requestRandomHashCreation(skillWalletOwner);
    }

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) override external {
        // TODO: Validate that the msg.sender is valid community

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");

        _skillSets[skillWalletId] = newSkillSet;

        emit SkillSetUpdated(skillWalletId, newSkillSet);
    }

    function activateSkillWallet(uint256 skillWalletId) override external onlyOwner {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_activeCommunities[skillWalletId] != address(0), "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet.");
        require(_activatedSkillWallets[skillWalletId] == false, "SkillWallet: Skill wallet already activated");

        _activatedSkillWallets[skillWalletId] = true;

        emit SkillWalletActivated(skillWalletId);
    }


    function changeCommunity(uint256 skillWalletId) override external {
        // TODO: Validate that the msg.sender is valid community

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");

        _activeCommunities[skillWalletId] = msg.sender;
        _communityHistory[skillWalletId].push(msg.sender);

        emit SkillWalletCommunityChanged(skillWalletId, msg.sender);
    }

    function _requestRandomHashCreation(address user) internal returns (bytes32 requestId) {
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);


        string memory url = "https://api.distributed.town/api/skillwallet";
        // string memory url = "https://api.distributed.town/api/skillWallet/createRandomString";
        // Set the URL to perform the GET request on
        request.add("get", url);

        //        request.add("queryParams", abi.encodePacked("user=", user));
        request.add("queryParams", "address=0xe5dfc64fad45122545b0a5b88726ff7858509600");

        request.add("path", "nickname");

        // Sends the request
        return sendChainlinkRequest(request, fee);

    }

    /**
     * @notice The fulfill method from requests created by this contract
     * @dev The recordChainlinkFulfillment protects this function from being called
     * by anyone other than the oracle address that the request was sent to
     * @param _requestId The ID that was generated for the request
     * @param _data The answer provided by the oracle
     */
    function fulfill(bytes32 _requestId, bytes32 _data)
    public
    recordChainlinkFulfillment(_requestId)
    {
        _createSkillWallet(string(abi.encodePacked(_data)));
    }

    function _createSkillWallet(string memory randomString) internal {
        uint256 tokenId = _skillWalletCounter.current();

        _safeMint(_skillWalletOwner, tokenId);
        _activeCommunities[tokenId] = _community;
        _communityHistory[tokenId].push(_community);
        _skillSets[tokenId] = _skillSet;
        _urls[tokenId] = _url;
        _skillWalletsByOwner[_skillWalletOwner] = tokenId;
        _randomStrings[_skillWalletOwner] = randomString;

        _skillWalletCounter.increment();

        emit SkillWalletCreated(_skillWalletOwner, _community, tokenId, _skillSet, randomString);

        Community community = Community(_community);
        community.skillWalletRegistered(tokenId, _skillWalletOwner);

        // reset variables
        _skillWalletOwner = address(0);
        _community = address(0);
        _url = "";
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
     * @param _requestId The ID that was generated for the request to cancel
     * @param _payment The payment specified for the request to cancel
     * @param _callbackFunctionId The bytes4 callback function ID specified for
     * the request to cancel
     * @param _expiration The expiration generated for the request to cancel
     */
    function cancelRequest(
        bytes32 _requestId,
        uint256 _payment,
        bytes4 _callbackFunctionId,
        uint256 _expiration
    )
    public
    onlyOwner
    {
        cancelChainlinkRequest(_requestId, _payment, _callbackFunctionId, _expiration);
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

    function isSkillWalletRegistered(address skillWalletOwner) override external view returns (bool status) {
        require(skillWalletOwner != address(0), "SkillWallet: Invalid skillWalletOwner address");
        return balanceOf(skillWalletOwner) == 1;
    }

    function isSkillWalletActivated(uint256 skillWalletId) override external view returns (bool status) {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_activeCommunities[skillWalletId] != address(0), "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet.");

        return _activatedSkillWallets[skillWalletId];
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

    function getSkillWalletIdByOwner(address skillWalletOwner) override external view returns (uint256) {
        require(balanceOf(skillWalletOwner) == 1, "SkillWallet: The SkillWallet owner is invalid.");
        return _skillWalletsByOwner[skillWalletOwner];
    }

    function getSkillSet(uint256 skillWalletId) override external view returns (Types.SkillSet memory skillSet) {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_activeCommunities[skillWalletId] != address(0), "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet.");

        return _skillSets[skillWalletId];
    }

    function getRandomString(address skillWalletOwner) override external view returns (string memory randomString) {
        require(balanceOf(skillWalletOwner) == 1, "SkillWallet: The SkillWallet owner is invalid.");

        return _randomStrings[skillWalletOwner];
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