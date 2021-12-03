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
        address _membershipFactory,
        Types.PartnersAgreementData memory pa
    ) public override returns (address) {
        address paAddr = address(new PartnersAgreement(_membershipFactory, pa));

        return paAddr;
    }
}
