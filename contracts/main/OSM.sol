//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./ISkillWallet.sol";
import "./ISWActionExecutor.sol";
import "@chainlink/contracts/src/v0.6/ChainlinkClient.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title SkillWallet OSM implementation
 *
 * @dev Implementation of the Offchain Signature Mechanism contract using chainlink EA
 * @author DistributedTown
 */
contract OffchainSignatureMechanism is ChainlinkClient {
    using Strings for uint256;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    ISkillWallet skillWallet;

    event ValidationPassed(bytes32 requestId);

    event ValidationFailed(bytes32 requestId);

    event ValidationRequestIdSent(
        bytes32 requestId,
        address caller,
        uint256 tokenId
    );

    mapping(bytes32 => Types.SWValidationRequest)
        private clReqIdToValidationRequest;

    mapping(bytes32 => bool) validReqIds;

    constructor(address _linkToken, address _oracle) public {
        setChainlinkToken(_linkToken);
        oracle = _oracle;
        jobId = "31061086cb2749f7a3f99f2d5179caf7";
        fee = 0.1 * 10**18; // 0.1 LINK
        skillWallet = ISkillWallet(msg.sender);
    }

    function validate(
        string calldata signature,
        uint256 tokenId,
        uint256 action,
        string[] memory stringParams,
        uint256[] memory intParams,
        address[] memory addressParams
    ) public {
        require(
            bytes(skillWallet.getPubKeyBySkillWalletId(tokenId)).length > 0,
            "PubKey should be assigned to the skill walletID first!"
        );

        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.validationCallback.selector
        );
        req.add("pubKey", skillWallet.getPubKeyBySkillWalletId(tokenId));
        req.add("signature", signature);
        req.add(
            "getNonceUrl",
            string(
                abi.encodePacked(
                    "https://api.skillwallet.id/api/skillwallet/",
                    tokenId.toString(),
                    "/nonces?action=",
                    action.toString()
                )
            )
        );
        req.add(
            "delNonceUrl",
            string(
                abi.encodePacked(
                    "https://api.skillwallet.id/api/skillwallet/",
                    tokenId.toString(),
                    "/nonces?action=",
                    action.toString()
                )
            )
        );
        address caller = skillWallet.ownerOf(tokenId);
        bytes32 reqId = sendChainlinkRequestTo(oracle, req, fee);

        clReqIdToValidationRequest[reqId] = Types.SWValidationRequest(
            caller,
            Types.Action(action),
            Types.Params(stringParams, intParams, addressParams)
        );

        emit ValidationRequestIdSent(reqId, caller, tokenId);
    }

    function validationCallback(bytes32 _requestId, bool _isValid)
        public
        recordChainlinkFulfillment(_requestId)
    {
        // add a require here so that only the oracle contract can
        // call the fulfill alarm method
        Types.SWValidationRequest memory req = clReqIdToValidationRequest[
            _requestId
        ];
        if (_isValid) {
            emit ValidationPassed(_requestId);
            validReqIds[_requestId] = true;

            if (req.action == Types.Action.Login) {
                return;
            } else if (req.action == Types.Action.Activate) {
                skillWallet.activateSkillWallet(
                    skillWallet.getSkillWalletIdByOwner(req.caller)
                );
            } else {
                require(
                    skillWallet.isSkillWalletActivated(
                        skillWallet.getSkillWalletIdByOwner(req.caller)
                    ),
                    "SkillWallet must be activated first!"
                );

                ISWActionExecutor actionExecutor = ISWActionExecutor(
                    skillWallet.getContractAddressPerAction(
                        req.action,
                        req.caller
                    )
                );

                actionExecutor.execute(
                    req.action,
                    req.caller,
                    req.params.intParams,
                    req.params.stringParams,
                    req.params.addressParams
                );
            }
        } else {
            emit ValidationFailed(_requestId);
        }
    }
}
