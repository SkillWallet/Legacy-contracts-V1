//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./Interaction.sol";

contract InteractionNFTFactory {
    function deployInteractionNFT(uint256 rolesCount, uint256 totalSupply) public returns (address) {
        address interactionNFT = address(new Interactions(msg.sender));

        return interactionNFT;
    }
}