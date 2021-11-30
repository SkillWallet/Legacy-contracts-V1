//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./PartnersAgreement.sol";
import "../interfaces/IPartnersAgreementFactory.sol";

contract PartnersAgreementFactory is IPartnersAgreementFactory {
    //TODO: Change to constant before prod
    uint256 public version;

    constructor(uint256 _version) public {
        version = _version;
    }

    function createPartnersAgreement(
        uint256 _version,
        address _partnersContract,
        address _owner,
        address _communityAddress,
        uint256 _rolesCount,
        uint256 _numberOfActions,
        address _membershipFactory,
        address _interactionsContract,
        address _membershipContract,
        address _interactionsQueryServer
    ) public override returns (address) {
        address paAddr = address(
            new PartnersAgreement(
                _version,
                _partnersContract,
                _owner,
                _communityAddress,
                _rolesCount,
                _numberOfActions,
                _membershipFactory,
                _interactionsContract,
                _membershipContract,
                _interactionsQueryServer
            )
        );

        return paAddr;
    }
}
