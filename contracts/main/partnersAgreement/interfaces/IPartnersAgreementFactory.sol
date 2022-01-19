//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "../../../imported/CommonTypes.sol";

interface IPartnersAgreementFactory {
    function createPartnersAgreement(
        address _membershipFactory,
        Types.PartnersAgreementData memory data,
        bytes32[] memory additionalFields,
        string[] memory additionalStrings
    ) external returns (address);
}
