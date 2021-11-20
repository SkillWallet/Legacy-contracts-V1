
//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../../utils/RoleUtils.sol";
import "../../utils/ERC1155Supply.sol";
import "../interfaces/IMembership.sol";
import "../interfaces/IPartnersAgreement.sol";

contract InteractionNFT is ERC1155Supply {
    using Counters for Counters.Counter;
    Counters.Counter interactionId;

    event MarkedAsInactive();

    mapping(address => uint) inactiveInteractions;
    IMembership membership;
    address partnersAgreementAddress;

    constructor(uint rolesCount, uint totalSupply, address membershipAddress) public ERC1155('') {
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

        partnersAgreementAddress = msg.sender;

        membership = IMembership(membershipAddress);
    }

    //TODO: call from token distribution, once there are funds distributed for a certain amount of interactions
    function markAsInactive(address owner, uint amount) public {
        require(owner != address(0), "no owner passed");
        require(amount >= balanceOf(owner, membership.getRole(owner)));

        inactiveInteractions[owner] += amount;

        emit MarkedAsInactive();
    }

    function getActiveInteractions(address user) public view returns(uint)  {
        uint role = membership.getRole(user);
        require(role != uint256(RoleUtils.Roles.NONE), "user has no role");
        
        uint balance = balanceOf(user, role);
        uint inactive = inactiveInteractions[user];
        return balance - inactive;
    }

    function getTotalSupplyAll() view public returns (uint256) {
        return totalSupply(1) + totalSupply(2) + totalSupply(3);
    }
}