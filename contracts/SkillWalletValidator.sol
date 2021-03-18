//SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <=0.8.0;

import "./ISkillWalletValidator.sol";
import "./ISkillWalletRegistry.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";


/// @author DistributedTown team
/// @title SkillWalletValidator contract implementation
contract SkillWalletValidator is ChainlinkClient, ISkillWalletValidator {

    ///@notice SkillWalletRequestFulfilled event, emitted when the Chainlink request is fulfilled
    event SkillWalletRequestFulfilled(bytes32 _requestId, bytes32 _hash, bool _isValid, bool _isConfirmed, string _type);

    ///@dev Used for identifying this smart contract
    bytes4 public constant override IDENTITY = 0x5e22cfc7;

    ///@dev Used for identifying this smart contract
    string private constant PATH = "isValid";

    ///@dev Create request specific variables
    bool public override isCreateValid;
    bool public override isCreateFulfilled;
    bool public override isCreateRequested;
    bool public override isCreateConfirmed;

    ///@dev Update request specific variables
    bool public override isUpdateValid;
    bool public override isUpdateFulfilled;
    bool public override isUpdateRequested;
    bool public override isUpdateConfirmed;

    ///@dev The SkillWallet hash that we will be verifying for the create skill wallet request
    bytes32 public override skillWalletHashOnCreate;

    ///@dev The SkillWallet hash that we will be verifying for the create skill wallet request
    bytes32 public override skillWalletHashOnUpdate;

    ///@dev The skill wallet registry
    address public override skillWalletRegistry;

    ///@dev Chainlink specific variables
    bytes32 private jobId;
    uint256 private fee;

    ///@dev Base URL for the API call
    string private baseUrl;

    /**
     * Network: Kovan
     * Oracle: 0x2f90A6D021db21e1B2A077c5a37B3C7E75D15b7e
     * Job ID: 6d914edc36e14d6c880c9c55bda5bc04 (ethbool)
     * Fee: 0.1 LINK
     */

    ///@dev Initialize the contract by setting the oracle address, jobId and the base url
    ///@param _oracle The address of the Chainlink oracle
    ///@param _jobId The id of the Chainlink job
    ///@param _baseUrl The base url of the backend to be called
    constructor(address _oracle, bytes32 _jobId, string memory _baseUrl) public {
        setPublicChainlinkToken();
        setChainlinkOracle(_oracle);
        jobId = _jobId;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        skillWalletRegistry = msg.sender;
        baseUrl = _baseUrl;
    }


    ///@dev Create a Chainlink request for validating the SkillWallet hash, called on Skill wallet create
    ///@param _hash The SkillWallet hash to be validated
    ///@return requestId The Chainlink request id
    function requestIsSkillWalletValidOnCreate(bytes32 _hash) public override returns (bytes32 requestId)
    {
        require(msg.sender == skillWalletRegistry, "SkillWalletValidator: Only the SkillWalletRegistry can call this operation");
        require(!isCreateRequested, "SkillWalletValidator: Create request already sent");

        isCreateValid = false;
        isCreateFulfilled = false;
        isCreateRequested = true;
        isCreateConfirmed = false;
        skillWalletHashOnCreate = _hash;

        return _buildAndSendValidationRequest(_hash, this.fulfillCreate.selector);
    }


    ///@dev Create a Chainlink request for validating the SkillWallet hash, called on Skill wallet update
    ///@param _hash The SkillWallet hash to be validated
    ///@return requestId The Chainlink request id
    function requestIsSkillWalletValidOnUpdate(bytes32 _hash) public override returns (bytes32 requestId)
    {
        require(msg.sender == skillWalletRegistry, "SkillWalletValidator: Only the SkillWalletRegistry can call this operation");
        require(!isUpdateRequested, "SkillWalletValidator: Update request already sent");

        isUpdateValid = false;
        isUpdateFulfilled = false;
        isUpdateRequested = true;
        isUpdateConfirmed = false;
        skillWalletHashOnUpdate = _hash;

        return _buildAndSendValidationRequest(_hash, this.fulfillUpdate.selector);
    }


    ///@dev Build and send a Chainlink request for validating the skill wallet hash
    ///@param validationHash The SkillWallet hash to be validated
    ///@param functionSelector The selector of the fulfillment function to be called
    ///@return requestId The id of the sent request
    function _buildAndSendValidationRequest(bytes32 validationHash, bytes4 functionSelector) private returns (bytes32 requestId) {

        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), functionSelector);

        // Set the URL to perform the GET request on
        request.add("get", baseUrl);
        request.add("queryParams", string(
        abi.encodePacked(
        "hash=",
        validationHash
        )));

        request.add("path", "isValid");

        // Sends the request
        return sendChainlinkRequest(request, fee);

    }


    ///@dev Fulfill the sent Chainlink request for skill wallet hash validation on create, called by the Chainlink oracle, emits {SkillWalletRequestFulfilled} event
    ///@param _requestId The id of the request being fufilled
    ///@param _isValid The backend API response
    function fulfillCreate(bytes32 _requestId, bool _isValid) public recordChainlinkFulfillment(_requestId)
    {
        require(skillWalletRegistry != address(0), "SkillWalletValidator: SkillWalletRegistry not set");

        if(_isValid) {
            isCreateConfirmed = ISkillWalletRegistry(skillWalletRegistry).confirmSkillWalletOnCreate(skillWalletHashOnCreate);
        }

        isCreateValid = _isValid;
        isCreateFulfilled = true;
        isCreateRequested = false;

        emit SkillWalletRequestFulfilled(_requestId, skillWalletHashOnCreate, _isValid, isCreateConfirmed, "create");
    }


    ///@dev Fulfil the sent Chainlink request, called by the Chainlink oracle, emits {SkillWalletRequestFulfilled} event
    ///@param _requestId The id of the request being fufilled
    ///@param _isValid The backend API response
    function fulfillUpdate(bytes32 _requestId, bool _isValid) public recordChainlinkFulfillment(_requestId)
    {
        require(skillWalletRegistry != address(0), "SkillWalletValidator: SkillWalletRegistry not set");

        if(_isValid) {
            isUpdateConfirmed = ISkillWalletRegistry(skillWalletRegistry).confirmSkillWalletOnUpdate(skillWalletHashOnUpdate);
        }

        isUpdateValid = _isValid;
        isUpdateFulfilled = true;
        isUpdateRequested = false;

        emit SkillWalletRequestFulfilled(_requestId, skillWalletHashOnUpdate, _isValid, isUpdateConfirmed, "update");
    }


    ///@dev Reset the sent create request, callable only by the skill wallet registry
    function resetCreateRequest() public override {
        require(isCreateRequested, "SkillWalletValidator: Create request not sent.");
        require(msg.sender == skillWalletRegistry, "SkillWalletValidator: Only the SkillWalletRegistry can call this operation.");

        isCreateValid = false;
        isCreateFulfilled = false;
        isCreateRequested = false;
        isCreateConfirmed = false;
    }

    ///@dev Reset the sent update request, callable only by the skill wallet registry
    function resetUpdateRequest() public override {
        require(isUpdateRequested, "SkillWalletValidator: Update request not sent.");
        require(msg.sender == skillWalletRegistry, "SkillWalletValidator: Only the SkillWalletRegistry can call this operation.");

        isUpdateValid = false;
        isUpdateFulfilled = false;
        isUpdateRequested = false;
        isUpdateConfirmed = false;
    }


}