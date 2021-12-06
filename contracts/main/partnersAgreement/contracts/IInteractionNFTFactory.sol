//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

interface IInteractionNFTFactory {
    function deployInteractionNFT(uint256 rolesCount, uint256 totalSupply) external returns (address);
}