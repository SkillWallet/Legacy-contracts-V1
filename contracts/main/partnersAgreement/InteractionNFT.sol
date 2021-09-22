
//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../utils/RoleUtils.sol";
import "../utils/ERC1155Supply.sol";

contract InteractionNFT is ERC1155Supply {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    Counters.Counter interactionId;

    event MarkedAsInactive();
    event UserRoleAssigned();

    mapping(address => RoleUtils.Roles) public userRoles;
    mapping(RoleUtils.Roles => address[]) public usersPerRole;

    mapping(address => uint) inactiveInteractions;

    constructor(uint rolesCount, uint totalSupply) public ERC1155('') {
        require(rolesCount == 2 || rolesCount == 3, "Invalid roles count!");

        uint256[3] memory roleCoefs = RoleUtils.getRolesCoefs(rolesCount);
        uint256 supplied = 0;

        for(uint256 i = 1; i <= rolesCount; i++) {
            uint256 roleTokens = totalSupply.mul(roleCoefs[i - 1]).div(100);
            _mint(msg.sender, i, roleTokens, "");
            supplied = supplied.add(roleTokens);
        }

        if (supplied < totalSupply) {
            _mint(msg.sender, rolesCount, totalSupply - supplied, "");
        }
    }

    function addUserToRole(address user, RoleUtils.Roles role) public {
        require(user != address(0), "No user passed");
        require(userRoles[user] == RoleUtils.Roles.NONE, "already has role");

        userRoles[user] = role;
        usersPerRole[role].push(user);

        emit UserRoleAssigned();

    }

    //TODO: call from token distribution, once there are funds distributed for a certain amount of interactions
    function markAsInactive(address owner, uint amount) public {
        require(owner != address(0), "no owner passed");
        require(amount >= balanceOf(owner, uint256(userRoles[owner])));

        inactiveInteractions[owner] += amount;

        emit MarkedAsInactive();
    }

    function getActiveInteractions(address user) public view returns(uint)  {
        require(userRoles[user] != RoleUtils.Roles.NONE, "user has no role");
        
        uint balance = balanceOf(user, uint256(userRoles[user]));
        uint inactive = inactiveInteractions[user];
        return balance - inactive;
    }

    function getRoleIds() pure public returns(uint256[3] memory) {
        uint256[3] memory roles;
        roles[0] = 1;
        roles[1] = 2;
        roles[2] = 3;
        return roles;
    }

    function getUsersPerRole(uint role) view public returns(address[] memory) {
        return usersPerRole[RoleUtils.Roles(role)];
    }
}