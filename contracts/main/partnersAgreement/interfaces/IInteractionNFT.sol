//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IInteractionNFT is IERC1155 {
    event MarkedAsInactive();
    
    function getActiveInteractions(address user) external view returns (uint256);

    function getTotalSupplyAll() external view returns (uint256);
}
