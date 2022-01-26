//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface IMembershipFactory {
    function createMembership(address skillWalletAddress,  address partnersAgreementAddr) external returns (address);
}
