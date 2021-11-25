//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

interface IPartnersRegistry {
    event PartnersAgreementCreated(
        address partnersAgreementAddress,
        address communityAddress
    );

    //TODO: for tests only should be removed one upgradability is implemented
    //Also possible to create PA factory and move version there
    function setVersion(uint256 _version) external;

    function getPartnerAgreementAddresses()
        external
        view
        returns (address[] memory);

    function create(
        string memory metadata,
        uint256 template,
        uint256 rolesCount,
        uint256 numberOfActions,
        address partnersContractAddress,
        uint256 membersAllowed,
        uint256 coreTeamMembers
    ) external;

    function migrate(address _agreement) external;
}
