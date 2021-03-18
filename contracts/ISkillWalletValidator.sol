//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

/// @author DistributedTown team
/// @title ISkillWalletValidator contract interface
interface ISkillWalletValidator {

    function IDENTITY() external view returns (bytes4);

    function isValid() external view returns (bool);

    function isFulfilled() external view returns (bool);

    function isRequested() external view returns (bool);

    function isConfirmed() external view returns (bool);

    ///@dev The SkillWallet hash to be validated
    function skillWalletHash() external view returns (bytes32);

    ///@dev Create a Chainlink request for validating the SkillWallet hash
    ///@param _hash The SkillWallet hash to be validated
    ///@return requestId The Chainlink request id
    function requestIsSkillWalletValid(bytes32 _hash) external returns (bytes32 requestId);
}