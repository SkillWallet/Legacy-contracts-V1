//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./ISkillWallet.sol";

/**
 * @title Membership contract connecting Project to SkillWallet
 *
 * @dev Implementation of the Membership contract
 * @author DistributedTown
 */
contract Membership is IERC721Metadata, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _membershipCounter;
    ISkillWallet skillWallet;

    mapping(uint => uint) membershipIDToProject;
    mapping(uint256 => uint256[]) userMemberships;

    event MembershipCreated(
        uint256 membershipTokenId,
        uint256 skillWalletId,
        uint256 projectId
    );

    constructor(address skillWalletAddress) public ERC721("Membership", "MMB") {
        skillWallet = ISkillWallet(skillWalletAddress);
        _membershipCounter.increment();
    }

    function create(string calldata url, uint projectId) external {
        require(
            skillWallet.isSkillWalletRegistered(msg.sender),
            "SkillWallet not yet registered"
        );

        uint256 skillWalletId = skillWallet.getSkillWalletIdByOwner(msg.sender);

        require(
            skillWallet.isSkillWalletActivated(skillWalletId),
            "SkillWallet should be activated!"
        );

        uint256 tokenId = _membershipCounter.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, url);

        userMemberships[skillWalletId].push(tokenId);

        membershipIDToProject[skillWalletId] = projectId;
        _membershipCounter.increment();

        emit MembershipCreated(tokenId, skillWalletId, projectId);
    }

    function getSkillWalletMemberships(uint256 skillWalletID)
        public
        view
        returns (uint256[] memory)
    {
        return userMemberships[skillWalletID];
    }
}
