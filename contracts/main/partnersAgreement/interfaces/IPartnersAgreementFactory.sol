//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "../../../imported/CommonTypes.sol";

interface IPartnersAgreementFactory {
    function createPartnersAgreement(
        address _chainlinkToken,
        address _oracle,
        address _membershipFactory,
        Types.PartnersAgreementData memory data
    ) external returns (address);
}
