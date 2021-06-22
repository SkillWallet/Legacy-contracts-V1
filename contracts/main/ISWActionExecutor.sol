//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "../imported/CommonTypes.sol";

interface ISWActionExecutor {
    event ActonExecuted(
        address indexed contractAddress,
        uint256 indexed action
    );

    function execute(
        Types.Action action,
        address caller,
        uint[] memory intParams,
        string[] memory stringParams,
        address[] memory addressParams
    ) external;
}
