//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
//import "./ISkillWallet.sol";
import "../imported/CommonTypes.sol";
import "../imported/Community.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

/**
 * @title DistributedTown SkillWallet
 *
 * @dev Implementation of the SkillWallet contract
 * @author DistributedTown
 */
contract SkillWallet is VRFConsumerBase, ISkillWallet, ERC721, Ownable {

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

    // Mapping from token ID to random number used for the QR code verification
    mapping (uint256 => uint256) private _randomNumbers;

    Counters.Counter private _skillWalletCounter;

    // Chainlink specific variables
    uint256 private fee;
    bytes32 private keyHash;

    // Chainlink helper variables, used for the data capturing before the chainlink request
    address private _skillWalletOwner;
    address private _community;
    Types.SkillSet private _skillSet;
    string private _url;


    /**
     * @notice Deploy the contract with a specified address for the LINK token, VRF coordinator address and key hash
     * @dev Sets the storage for the specified addresses and jobId
     * @param _link The address of the LINK token contract
     * @param _vrfCoordinator The address of the Chainlink VRF coordinatior
     * @param _keyHash The id of the Chainlink job
     */
    constructor (address _link, address _vrfCoordinator, bytes32 _keyHash) public ERC721("SkillWallet", "SW") VRFConsumerBase(
        _vrfCoordinator, // VRF Coordinator
        _link  // LINK Token
    ){
        keyHash = _keyHash;
        fee = 0.0001 * 10 ** 18; // 0.01 LINK
    }

    function create(address skillWalletOwner, Types.SkillSet memory skillSet, string memory url) override external {

        // TODO: Verify that the msg.sender is valid community

        require(balanceOf(skillWalletOwner) == 0, "SkillWallet: There is SkillWallet already registered for this address.");
        require(LINK.balanceOf(address(this)) >= fee, "SkillWallet: Not enough LINK - fill contract with faucet");

        _skillWalletOwner = skillWalletOwner;
        _skillSet = skillSet;
        _url = url;
        _community = msg.sender;

        requestRandomness(keyHash, fee, block.number);
    }

    function cancelRequest() external onlyOwner {
        _resetChainlinkVariables();
    }

    function updateSkillSet(uint256 skillWalletId, Types.SkillSet memory newSkillSet) override external {
        // TODO: Validate that the msg.sender is valid community

        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");

        _skillSets[skillWalletId] = newSkillSet;

        emit SkillSetUpdated(skillWalletId, newSkillSet);
    }

    function activateSkillWallet(uint256 skillWalletId, uint256 randomNumber) override external onlyOwner {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_activeCommunities[skillWalletId] != address(0), "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet.");
        require(_activatedSkillWallets[skillWalletId] == false, "SkillWallet: Skill wallet already activated");

        require(_randomNumbers[skillWalletId] == randomNumber, "SkillWallet: Invalid random number passed.");

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


    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        _createSkillWallet(randomness);
    }

    function _createSkillWallet(uint256 randomNumber) internal {
        uint256 tokenId = _skillWalletCounter.current();

        _safeMint(_skillWalletOwner, tokenId);
        _activeCommunities[tokenId] = _community;
        _communityHistory[tokenId].push(_community);
        _skillSets[tokenId] = _skillSet;
        _urls[tokenId] = _url;
        _skillWalletsByOwner[_skillWalletOwner] = tokenId;
        _randomNumbers[tokenId] = randomNumber;

        _skillWalletCounter.increment();

        emit SkillWalletCreated(_skillWalletOwner, _community, tokenId, _skillSet, randomNumber);

        Community community = Community(_community);
        community.skillWalletRegistered(tokenId, _skillWalletOwner);

        _resetChainlinkVariables();
    }

    function _resetChainlinkVariables() internal {
        // reset variables
        _skillWalletOwner = address(0);
        _community = address(0);
        _url = "";
    }

    /**
     * @notice Allows the owner to withdraw any LINK balance on the contract
     */
    function withdrawLink() public onlyOwner {
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
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

    function getRandomNumber(uint256 skillWalletId) override external view returns (uint256 randomNumber) {
        require(skillWalletId < _skillWalletCounter.current(), "SkillWallet: skillWalletId out of range.");
        require(_activeCommunities[skillWalletId] != address(0), "SkillWallet: The SkillWallet is not in any community, invalid SkillWallet.");

        return _randomNumbers[skillWalletId];
    }



}