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

contract Community is ICommunity {
    address private skillWalletAddress;

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

    // check if it's called only from deployer.
    function joinNewMember(
        uint64 displayStringId1,
        uint8 level1,
        uint64 displayStringId2,
        uint8 level2,
        uint64 displayStringId3,
        uint8 level3,
        string memory uri,
        uint256 credits
    ) public override {
        ISkillWallet skillWallet = ISkillWallet(skillWalletAddress);
        Types.SkillSet memory skillSet =
            Types.SkillSet(
                Types.Skill(displayStringId1, level1),
                Types.Skill(displayStringId2, level2),
                Types.Skill(displayStringId3, level3)
            );
        skillWallet.create(msg.sender, skillSet, uri);
        uint256 token = skillWallet.getSkillWalletIdByOwner(msg.sender);

        emit MemberAdded(msg.sender, token, credits);
    }
}
