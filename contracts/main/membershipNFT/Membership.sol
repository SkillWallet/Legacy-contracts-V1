//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../ISkillWallet.sol";
import "./IMembership.sol";
import "../partnersAgreement/interfaces/IPartnersAgreement.sol";

/*
 * @title Membership contract for minting Membership NFTs
 *
 * @dev Implementation of the Membership contract
 * @author DistributedTown
 */
contract Membership is IMembership, ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _membershipCounter;

    mapping(uint256 => uint256) public skillWalletToMembershipID;

    IPartnersAgreement partnersAgreement;
    ISkillWallet skillWallet;

    constructor(address skillWalletAddress, address partnersAgreementAddr)
        public
        ERC721("Membership", "MMB")
    {
        partnersAgreement = IPartnersAgreement(partnersAgreementAddr);
        skillWallet = ISkillWallet(skillWalletAddress);
        _membershipCounter.increment();
    }

    function create(string calldata url) public override {

        uint256 skillWalletId = skillWallet.getSkillWalletIdByOwner(msg.sender);

        require(
            skillWallet.getActiveCommunity(skillWalletId) ==
                partnersAgreement.communityAddress(),
            "Can mint membership NFT only if a member"
        );

        require(
            balanceOf(msg.sender) == 0,
            "Has already minted Membership NFT"
        );


        uint256 tokenId = _membershipCounter.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, url);

        skillWalletToMembershipID[skillWalletId] = tokenId;

        _membershipCounter.increment();

        emit MembershipCreated(tokenId, skillWalletId);
    }
}
