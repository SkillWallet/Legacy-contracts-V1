//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

interface IActivities is IERC721 {
    function createActivity(uint256 _type, string memory _uri) external;

    function finalizeActivity(
        uint256 _id,
        string memory _uri,
        address[] calldata members
    ) external;

    function createTask(string memory _url) external;

    function takeTask(uint256 _activityId) external;

    function finilizeTask(uint256 _activityId) external;

    function getActivitiesByType(uint256 _type)
        external
        view
        returns (uint256[] memory);

function getInteractionsAddr() external view returns (address);
}
