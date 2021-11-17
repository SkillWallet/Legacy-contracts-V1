//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";

/*
 * @title Membership contract for minting Membership NFTs
 *
 * @dev Implementation of the Membership contract
 * @author DistributedTown
 */
interface IMembership is IERC721Metadata {
    event MembershipCreated(uint256 membershipTokenId, uint256 skillWalletId);

    function create(string calldata url, uint256 role) external;

    function getRole(uint skillWalletId) external view returns(uint);
    
    function getRole(address member) external view returns(uint);

}
