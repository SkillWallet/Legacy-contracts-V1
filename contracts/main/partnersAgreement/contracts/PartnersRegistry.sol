//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "../interfaces/IPartnersRegistry.sol";
import "../../../imported/IDistributedTown.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interfaces/IPartnersAgreementFactory.sol";
import "../interfaces/IPartnersAgreement.sol";
import "../../../imported/CommonTypes.sol";

contract PartnersRegistry is IPartnersRegistry, Initializable {
    //versioning
    uint256 public version;

    // distributedTown contract
    IDistributedTown distributedTown;

    // agreements
    address[] public agreements;
    mapping(address => uint256) public agreementIds;

    // factories
    address partnersAgreementFactory;
    address membershipFactory;
    address interactionsQueryServer;

    function initialize(
        address _distributedTownAddress,
        address _partnersAgreementFactoryAddress,
        address _membershipFactory,
        address _interactionsQueryServer
    ) public initializer {
        distributedTown = IDistributedTown(_distributedTownAddress);
        partnersAgreementFactory = _partnersAgreementFactoryAddress;
        membershipFactory = _membershipFactory;
        interactionsQueryServer = _interactionsQueryServer;

        version = 1;
    }

    //TODO: for tests only should be removed one upgradability is implemented
    //Also possible to create PA factory and move version there
    function setVersion(uint256 _version) public override {
        version = _version;
    }

    function getPartnerAgreementAddresses()
        public
        view
        override
        returns (address[] memory)
    {
        return agreements;
    }

    function create(
        string memory metadata,
        uint256 template,
        uint256 rolesCount,
        uint256 numberOfActions,
        address partnersContractAddress,
        uint256 membersAllowed,
        uint256 coreTeamMembers,
        bytes32[] memory additionalFields,
        string[] memory additionalStrings
    ) public override {
        require(
            template >= 0 && template <= 2,
            "Template should be between 0 and 2"
        );
        require(
            numberOfActions > 0 && numberOfActions <= 100,
            "Number of actions should be between 1 and 100"
        );

        distributedTown.createCommunity(
            metadata,
            template,
            membersAllowed,
            msg.sender
        );
        address communityAddress = distributedTown.getCommunityByOwner(
            msg.sender
        );

        require(
            communityAddress != address(0),
            "Community failed to be created!"
        );

        if (partnersContractAddress == address(0))
            partnersContractAddress = communityAddress;

        address[] memory partnersContracts = new address[](1);
        partnersContracts[0] = partnersContractAddress;
        address[] memory whitelistMembers = new address[](0);
        address paAddr = IPartnersAgreementFactory(partnersAgreementFactory)
            .createPartnersAgreement(
                membershipFactory,
                Types.PartnersAgreementData(
                    version,
                    msg.sender,
                    communityAddress,
                    partnersContracts,
                    rolesCount,
                    address(0),
                    address(0),
                    numberOfActions,
                    coreTeamMembers,
                    whitelistMembers,
                    interactionsQueryServer
                ),
                additionalFields,
                additionalStrings
            );

        agreementIds[paAddr] = agreements.length;
        agreements.push(paAddr);

        emit PartnersAgreementCreated(paAddr, communityAddress);
    }

    function migrate(address _agreement) public override {
        uint256 agreementId = agreementIds[_agreement];

        require(
            agreements[agreementId] == _agreement,
            "wrong agreement address"
        );

        Types.PartnersAgreementData memory pa = IPartnersAgreement(_agreement)
            .getAgreementData();

        (bytes32[] memory addFields, string[] memory addStrings) = IPartnersAgreement(_agreement).getAdditionalFields();


        require(pa.version < version, "already latest version");
        require(pa.owner == msg.sender, "not agreement owner");

        pa.version = version;
        // todo: fix hard coded core team members
        address agreement = IPartnersAgreementFactory(partnersAgreementFactory)
            .createPartnersAgreement(
                membershipFactory,
                pa,
                addFields,
                addStrings
            );

        agreements[agreementId] = agreement;
        delete agreementIds[_agreement];
        agreementIds[agreement] = agreementId;
    }
}
