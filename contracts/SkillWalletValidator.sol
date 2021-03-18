//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./ISkillWalletValidator.sol";
import "./ISkillWalletRegistry.sol";
import "@chainlink/contracts/src/v0.7/ChainlinkClient.sol";


/// @author DistributedTown team
/// @title SkillWalletValidator contract implementation
contract SkillWalletValidator is ChainlinkClient, ISkillWalletValidator {

    ///@notice SkillWalletRequestFulfilled event, emitted when the Chainlink request is fulfilled
    event SkillWalletRequestFulfilled(bytes32 _requestId, bytes32 _hash, bool _isValid, bool _isConfirmed);

    ///@dev Used for identifying this smart contract
    bytes4 public override constant IDENTITY = 0x5e22cfc7;

    ///@dev Used for identifying the skill wallet registry smart contract
    bytes4 public constant SKILL_WALLET_REGISTRY_IDENTITY = 0x788ec99c;

    ///@dev Used for identifying this smart contract
    string private constant PATH = "isValid";

    ///@dev Request specific variables
    bool public override isValid;
    bool public override isFulfilled;
    bool public override isRequested;
    bool public override isConfirmed;

    ///@dev The SkillWallet hash that we will be verifying
    bytes32 public override skillWalletHash;

    ///@dev The skill wallet registry
    address public skillWalletRegistry;

    ///@dev Chainlink specific variables
    address private oracle;
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
        oracle = _oracle;
        jobId = _jobId;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        baseUrl = _baseUrl;
    }


    ///@dev Create a Chainlink request for validating the SkillWallet hash
    ///@param _hash The SkillWallet hash to be validated
    ///@return requestId The Chainlink request id
    function requestIsSkillWalletValid(bytes32 _hash) public override returns (bytes32 requestId)
    {
        require(ISkillWalletRegistry(msg.sender).IDENTITY() == SKILL_WALLET_REGISTRY_IDENTITY, "SkillWalletValidator: Only the SkillWalletRegistry can call this operation");
        require(!isRequested, "SkillWalletValidator: Request already sent");
        skillWalletRegistry = msg.sender;

        isValid = false;
        isFulfilled = false;
        isRequested = true;
        isConfirmed = false;
        skillWalletHash = _hash;
        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        request.add("get", baseUrl);
        request.add("queryParams", string(
                abi.encodePacked(
                    "hash=",
                    _hash
                )));

        request.add("path", PATH);

        // Sends the request
        return sendChainlinkRequestTo(oracle, request, fee);
    }


    ///@dev Fufill the sent Chainlink request, called by the Chainlink oracle, emits {SkillWalletRequestFulfilled} event
    ///@param _requestId The id of the request being fufilled
    ///@param _isValid The backend API response
    function fulfill(bytes32 _requestId, bool _isValid) public recordChainlinkFulfillment(_requestId)
    {
        if(_isValid && (skillWalletRegistry != address(0))) {
            isConfirmed = ISkillWalletRegistry(skillWalletRegistry).confirmSkillWallet(skillWalletHash);
        }

        isValid = _isValid;
        isFulfilled = true;
        isRequested = false;
        skillWalletRegistry = address(0);

        emit SkillWalletRequestFulfilled(_requestId, skillWalletHash, _isValid, isConfirmed);
    }

    ///@dev Reset the sent request, callable only by the original requester
    function reset() public {
        require(isRequested, "SkillWalletValidator: Request not sent.");
        require(msg.sender == skillWalletRegistry, "SkillWalletValidator: Only the requester can call this operation.");

        isValid = false;
        isFulfilled = false;
        isRequested = false;
        isConfirmed = false;
        skillWalletRegistry = address(0);
    }


}