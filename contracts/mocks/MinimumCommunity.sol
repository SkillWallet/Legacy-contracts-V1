//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "../imported/ICommunity.sol";
import "../main/ISkillWallet.sol";

/**
 * @title DistributedTown Community
 *
 * @dev Implementation of the Community concept in the scope of the DistributedTown project
 * @author DistributedTown
 */

contract MinimumCommunity is ICommunity {
    address private skillWalletAddress;
    mapping(address => bool) members;

    constructor(address _skillWalletAddress) public {
        skillWalletAddress = _skillWalletAddress;
    }

    function gigsAddr() public view override returns (address) {
        return address(0);
    }

    function getMembers() public view override returns (uint256[] memory) {
        uint256[] memory members = new uint256[](3);
        members[0] = 1;
        members[1] = 3;
        members[2] = 4;
        return members;
    }

    function getTokenId() public view override returns (uint256) {
        return 1;
    }

    function getTemplate() public view override returns (uint256) {
        return 1;
    }

    function getTreasuryBalance() public view override returns (uint256) {
        return 3000;
    }

    function getProjects() public view override returns (uint256[] memory) {
        uint256[] memory projects = new uint256[](3);
        projects[0] = 1;
        projects[1] = 3;
        projects[2] = 4;
        return projects;
    }

    function getProjectTreasuryAddress(uint256 projectId)
        public
        view
        override
        returns (address)
    {
        return address(0);
    }

    function balanceOf(address member) public view override returns (uint256) {
        return 3000;
    }


    function isMember(address member) public view override returns (bool) {
        return members[member];
    }

    function getMemberAddresses() public view override returns (address[] memory) {
        address[] memory res;
        return res;
    }

    function getSkillWalletAddress() public view override returns (address) {
        return skillWalletAddress;
    }

    // check if it's called only from deployer.
    function joinNewMember(
        string memory uri,
        RoleUtils.Roles role,
        uint256 credits
    ) public override {
        ISkillWallet skillWallet = ISkillWallet(skillWalletAddress);
        skillWallet.create(msg.sender, uri, role,false);
        uint256 token = skillWallet.getSkillWalletIdByOwner(msg.sender);
        members[msg.sender] = true;
        emit MemberAdded(msg.sender, token, credits);
    }
}
