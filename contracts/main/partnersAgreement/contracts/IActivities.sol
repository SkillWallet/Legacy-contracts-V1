//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

interface IActivities is IERC721 {
    function createActivity(uint256 _type, string memory _uri) external;

    function createTask(string memory _uri, address _creator) external;

    function takeTask(uint256 _activityId, address _taker) external;

    function finilizeTask(uint256 _activityId, address _taker) external; 
}