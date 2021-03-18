//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

interface ISkillWalletRegistry {

    function IDENTITY() external view returns (bytes4);

    function createSkillWallet(address user, bytes32 skillWalletHash) external;

    function confirmSkillWallet(bytes32 skillWalletHash) external returns (bool);


}