//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./IMembershipFactory.sol";
import "./Membership.sol";

/*
 * @title Membership contract for minting Membership NFTs
 *
 * @dev Implementation of the Membership contract
 * @author DistributedTown
 */
contract MembershipFactory is IMembershipFactory {
    //TODO: Change to constant before prod
    uint256 public version;

    constructor(uint256 _version) public {
        version = _version;
    }

    function createMembership(address _swAddress, address _partnersAgreementAddr)
        public
        override
        returns (address)
    {
        address memAddr = address(new Membership(_swAddress, _partnersAgreementAddr));

        return memAddr;
    }
}
