//SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <=0.8.0;

/// @author DistributedTown team
/// @title ISkillWalletValidator contract interface
interface ISkillWalletValidator {

    function IDENTITY() external view returns (bytes4);

    function skillWalletRegistry() external view returns (address);

    function isCreateValid() external view returns (bool);

    function isCreateFulfilled() external view returns (bool);

    function isCreateRequested() external view returns (bool);

    function isCreateConfirmed() external view returns (bool);

    function isUpdateValid() external view returns (bool);

    function isUpdateFulfilled() external view returns (bool);

    function isUpdateRequested() external view returns (bool);

    function isUpdateConfirmed() external view returns (bool);


    ///@dev The SkillWallet hash to be validated on create
    function skillWalletHashOnCreate() external view returns (bytes32);

    ///@dev The SkillWallet hash to be validated on update
    function skillWalletHashOnUpdate() external view returns (bytes32);


    ///@dev Create a Chainlink request for validating the SkillWallet hash, called on Skill wallet create
    ///@param _hash The SkillWallet hash to be validated
    ///@return requestId The Chainlink request id
    function requestIsSkillWalletValidOnCreate(bytes32 _hash) external returns (bytes32 requestId);


    ///@dev Create a Chainlink request for validating the SkillWallet hash, called on Skill wallet update
    ///@param _hash The SkillWallet hash to be validated
    ///@return requestId The Chainlink request id
    function requestIsSkillWalletValidOnUpdate(bytes32 _hash) external returns (bytes32 requestId);

    ///@dev Reset the sent create request, callable only by the skill wallet registry
    function resetCreateRequest() external;

    ///@dev Reset the sent update request, callable only by the skill wallet registry
    function resetUpdateRequest() external;


}