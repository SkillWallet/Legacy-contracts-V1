//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/utils/Counters.sol";
import "../../utils/RoleUtils.sol";
import "../../utils/ERC1155Supply.sol";
import "../../ISkillWallet.sol";
import "./PartnersAgreement.sol";
import "../../community/ICommunity.sol";

contract InteractionNFT is ERC1155Supply {
    event MarkedAsInactive();

    mapping(address => uint256) inactiveInteractions;
    address partnersAgreementAddress;

    constructor(
        address pa,
        uint256 rolesCount,
        uint256 totalSupply
    ) public ERC1155("") {
        require(rolesCount == 2 || rolesCount == 3, "Invalid roles count!");

        uint256[3] memory roleCoefs = RoleUtils.getRolesCoefs(rolesCount);
        uint256 supplied = 0;

        for (uint256 i = 1; i <= rolesCount; i++) {
            uint256 roleTokens = totalSupply.mul(roleCoefs[i - 1]).div(100);
            _mint(pa, i, roleTokens, "");
            supplied = supplied.add(roleTokens);
        }

        if (supplied < totalSupply) {
            _mint(pa, rolesCount, totalSupply - supplied, "");
        }

        partnersAgreementAddress = pa;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public override {
        if (from != partnersAgreementAddress)
            inactiveInteractions[from] += amount;

        super.safeTransferFrom(from, to, id, amount, data);
        emit MarkedAsInactive();
    }

    function getActiveInteractions(address user) public view returns (uint256) {
        uint256 role = uint256(
            ISkillWallet(IPartnersAgreement(msg.sender).getSkillWalletAddress())
                .getRole(user)
        );
        require(role != uint256(RoleUtils.Roles.NONE), "user has no role");

        uint256 balance = balanceOf(user, role);
        uint256 inactive = inactiveInteractions[user];
        return balance - inactive;
    }

    function getTotalSupplyAll() public view returns (uint256) {
        return totalSupply(1) + totalSupply(2) + totalSupply(3);
    }
}
