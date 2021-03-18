//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {DataTypes} from './utils/DataTypes.sol';
import "./ISkillWalletValidator.sol";
import "./ISkillWalletRegistry.sol";


contract SkillWalletRegistry  is ISkillWalletRegistry {


    bytes4 public constant override IDENTITY = 0x788ec99c;

    event SkillWalletCreationRequested(
        address user,
        bytes32 skillWalletHash
    );

    event SkillWalletUpdateRequested(
        address user,
        bytes32 skillWalletHash
    );


    event ErrorConfirmingSkillWallet(
        bytes32 skillWalletHash,
        string reason
    );


    event SkillWalletCreated(
        address user,
        bytes32 skillWalletHash
    );


    event SkillWalletUpdated(
        address user,
        bytes32 skillWalletHash
    );

    ISkillWalletValidator public oracle;

    mapping(address => DataTypes.SkillWallet) public skillWallets;

    address private newSkillWalletCreator;
    address private skillWalletUpdater;

    bool public createValidationRequested;

    bool public updateValidationRequested;


    constructor(address _oracle) {
        require(_oracle != address(0), "SkillWalletRegistry: The oracle can't be the zero address");

        oracle = ISkillWalletValidator(_oracle);
    }

    function createSkillWallet(address user, bytes32 skillWalletHash) public override {
        require(user == msg.sender, "SkillWalletRegistry: Only the sender can create SkillWallet for himself."); // TODO: Is this necessary?
        require(skillWallets[user].skillsHash.length == 0, "SkillWalletRegistry: Skill wallet already exists");
        require(!createValidationRequested, "SkillWalletRegistry: Skill wallet validation already requested");
        newSkillWalletCreator = user;
        createValidationRequested = true;

        require(!oracle.isCreateRequested(), "SkillWalletRegistry: Skill wallet create validation is already in progress");
        oracle.requestIsSkillWalletValidOnCreate(skillWalletHash);

        emit SkillWalletCreationRequested(user, skillWalletHash);
    }

    function confirmSkillWalletOnCreate(bytes32 skillWalletHash) public override returns (bool) {
        if (msg.sender != address(oracle)) {
            emit ErrorConfirmingSkillWallet(skillWalletHash, "SkillWalletRegistry: Not the oracle");
            return false;
        }
        if(!createValidationRequested) {
            emit ErrorConfirmingSkillWallet(skillWalletHash, "SkillWalletRegistry: Validation not requested yet");
            return false;
        }

        address[] memory erc20Tokens;
        DataTypes.SkillWallet memory skillWallet = DataTypes.SkillWallet(
            erc20Tokens,
            skillWalletHash
        );

        skillWallets[newSkillWalletCreator] = skillWallet;

        emit SkillWalletCreated(newSkillWalletCreator, skillWalletHash);

        newSkillWalletCreator = address(0);
        createValidationRequested = false;
        return true;
    }

    function updateSkillWallet(address user, bytes32 skillWalletHash) public override {
        require(user == msg.sender, "SkillWalletRegistry: Only the sender can update SkillWallet for himself."); // TODO: Is this necessary?
        require(skillWallets[user].skillsHash.length != 0, "SkillWalletRegistry: Skill wallet doesn't exists");
        require(!updateValidationRequested, "SkillWalletRegistry: Skill wallet validation already requested");
        skillWalletUpdater = user;
        updateValidationRequested = true;

        require(!oracle.isUpdateRequested(), "SkillWalletRegistry: Skill wallet validation is already in progress");
        oracle.requestIsSkillWalletValidOnUpdate(skillWalletHash);

        emit SkillWalletUpdateRequested(user, skillWalletHash);
    }


    function confirmSkillWalletOnUpdate(bytes32 skillWalletHash) public override returns (bool) {
        if (msg.sender != address(oracle)) {
            emit ErrorConfirmingSkillWallet(skillWalletHash, "SkillWalletRegistry: Not the oracle");
            return false;
        }
        if(!updateValidationRequested) {
            emit ErrorConfirmingSkillWallet(skillWalletHash, "SkillWalletRegistry: Validation not requested yet");
            return false;
        }

        skillWallets[skillWalletUpdater].skillsHash = skillWalletHash;

        emit SkillWalletUpdated(skillWalletUpdater, skillWalletHash);

        skillWalletUpdater = address(0);
        updateValidationRequested = false;
        return true;
    }




}