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

    mapping(uint => MembershipID) membershipIDs;
    mapping(uint => uint[]) userMemberships;

    event MembershipCreated(uint membershipTokenId, uint skillWalletId, uint projectId);
    struct MembershipID {
        uint skillWalletId;
        uint projectId;
        bool isActive;
    }

    constructor(address skillWalletAddress) public ERC721("Membership", "MMB") {
        skillWallet = ISkillWallet(skillWalletAddress);
        _membershipCounter.increment();
    }

    function create(
        uint projectId,
        string calldata url
    ) external {
       
       require(
           skillWallet.isSkillWalletRegistered(msg.sender), 'SkillWallet not yet registered'
       );

       uint skillWalletId = skillWallet.getSkillWalletIdByOwner(msg.sender);

       require(
           skillWallet.isSkillWalletActivated(skillWalletId),
           "SkillWallet should be activated!"
       );

        uint tokenId = _membershipCounter.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, url);

        userMemberships[skillWalletId].push(tokenId);

        _membershipCounter.increment();
        membershipIDs[tokenId] = MembershipID(skillWalletId, projectId, false);

        emit MembershipCreated(tokenId, skillWalletId, projectId);
    }

    function getSkillWalletMemberships(uint skillWalletID) public view returns (uint[] memory) {
        return userMemberships[skillWalletID];
    }
}
