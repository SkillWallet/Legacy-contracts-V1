//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../imported/Membership.sol";
import "../imported/Community.sol";
import "../utils/Types.sol";


interface ISkillWallet {

    function getMembership() external view returns (Membership);

    function getOwner() external view returns (address);

    function getMemberInfo() external view returns (Types.Member memory);

    function getCommunity() external view returns (Community);

}