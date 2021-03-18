//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import {DataTypes} from './utils/DataTypes.sol';
import "./ISkillWalletValidator.sol";
import "./ISkillWalletRegistry.sol";


contract SkillWalletRegistry  is ISkillWalletRegistry {


    bytes4 public override constant IDENTITY = 0x788ec99c;

    event SkillWalletCreationRequested(
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
    bool public validationRequested;


    constructor(address _oracle) {
        require(_oracle != address(0), "SkillWalletRegistry: The oracle can't be the zero address");

        oracle = ISkillWalletValidator(_oracle);
    }


    function createSkillWallet(address user, bytes32 skillWalletHash) public override {
        require(user == msg.sender, "SkillWalletRegistry: Only the sender can create SkillWallet for himself."); // TODO: Is this necessary?
        require(skillWallets[user].skillsHash.length == 0, "SkillWalletRegistry: Skill wallet already exists");
        require(!validationRequested, "SkillWalletRegistry: Skill wallet validation already requested");
        newSkillWalletCreator = user;
        validationRequested = true;

        require(!oracle.isRequested(), "SkillWalletRegistry: Skill wallet validation is already in progress");
        oracle.requestIsSkillWalletValid(skillWalletHash);

        emit SkillWalletCreationRequested(user, skillWalletHash);
    }

    function confirmSkillWallet(bytes32 skillWalletHash) public override returns (bool) {
        if (msg.sender != address(oracle)) {
            emit ErrorConfirmingSkillWallet(skillWalletHash, "SkillWalletRegistry: Not the oracle");
            return false;
        }
        if(!validationRequested) {
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
        validationRequested = false;


        return true;
    }




}