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

    // chainlink
    address oracle;
    address linkToken;

    // factories
    address partnersAgreementFactory;
    address membershipFactory;

    function initialize(
        address _distributedTownAddress,
        address _partnersAgreementFactoryAddress,
        address _membershipFactory,
        address _oracle,
        address _linkToken
    ) public initializer {
        distributedTown = IDistributedTown(_distributedTownAddress);
        partnersAgreementFactory = _partnersAgreementFactoryAddress;
        membershipFactory = _membershipFactory;

        oracle = _oracle;
        linkToken = _linkToken;
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
        uint256 coreTeamMembers
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

        address[] storage partnersContracts;
        partnersContracts.push(partnersContractAddress);
        address[] storage whitelistMembers;
        address paAddr = IPartnersAgreementFactory(partnersAgreementFactory)
            .createPartnersAgreement(
                linkToken,
                oracle,
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
                    whitelistMembers
                )
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

        require(pa.version < version, "already latest version");
        require(pa.owner == msg.sender, "not agreement owner");

        pa.version = version;
        // todo: fix hard coded core team members
        address agreement = IPartnersAgreementFactory(partnersAgreementFactory)
            .createPartnersAgreement(linkToken, oracle, membershipFactory, pa);

        agreements[agreementId] = agreement;
        delete agreementIds[_agreement];
        agreementIds[agreement] = agreementId;
    }
}
