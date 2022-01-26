//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "./PartnersAgreement.sol";
import "../interfaces/IPartnersAgreementFactory.sol";

contract PartnersAgreementFactory is IPartnersAgreementFactory {
    //TODO: Change to constant before prod
    uint256 public version;

    address interactionNFTFactory;

    constructor(uint256 _version, address _interactionNFTFactory) public {
        version = _version;
        interactionNFTFactory = _interactionNFTFactory;
    }

    function createPartnersAgreement(
        address skillWalletAddr,
        Types.PartnersAgreementData calldata pa
    ) public override returns (address) {
        address paAddr = address(new PartnersAgreement(skillWalletAddr, interactionNFTFactory, pa));

        return paAddr;
    }
}
