//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

interface IPartnersAgreementFactory {

    function createPartnersAgreement(
        uint256 _version,
        address _partnersContract,
        address _owner,
        address _communityAddress,
        uint256 _rolesCount,
        uint256 _numberOfActions,
        uint256 _coreTeamMembersCount,
        address _oracle,
        address _chainlinkToken,
        address _membershipFactory,
        address _interactionsContract,
        address _membershipContract
    ) external returns (address);
}
