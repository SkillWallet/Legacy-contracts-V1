//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./PartnersAgreement.sol";
import "../../imported/ICommunity.sol";
import "../../imported/IDistributedTown.sol";
import "../ISkillWallet.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract PartnersRegistry is Initializable {
    uint256 public version;
    
    event PartnersAgreementCreated(
        address partnersAgreementAddress,
        address communityAddress
    ); 
    IDistributedTown distributedTown;
    address[] public agreements;
    mapping (address => uint256) public agreementIds;
    address oracle;
    address linkToken;

    function initialize(
        address _distributedTownAddress,
        address _oracle,
        address _linkToken
    ) public initializer {
        distributedTown = IDistributedTown(_distributedTownAddress);
        oracle = _oracle;
        linkToken = _linkToken;
        version = 1;
    }

    //TODO: for tests only should be removed one upgradability is implemented
    //Also possible to create PA factory and move version there
    function setVersion(uint256 _version) public {
        version = _version;
    }

    function getPartnerAgreementAddresses()
        public
        view
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
        uint256 membersAllowed
    ) public {
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
        ICommunity community = ICommunity(communityAddress);
        uint256 credits;

        if (partnersContractAddress == address(0))
            partnersContractAddress = communityAddress;

        PartnersAgreement agreement = new PartnersAgreement(
            version,
            partnersContractAddress,
            msg.sender,
            communityAddress,
            rolesCount,
            numberOfActions,
            oracle,
            linkToken,
            address(0)
        );
        agreementIds[address(agreement)] = agreements.length;
        agreements.push(address(agreement));

        emit PartnersAgreementCreated(address(agreement), communityAddress);
    }

    function migrate(address _agreement) public {
        uint256 agreementId = agreementIds[_agreement];

        require(agreements[agreementId] == _agreement, "wrong agreement address");

        (
            uint256 agreementVersion,
            address owner,
            address communityAddress,
            address[] memory partnersContracts, //there can be many?
            uint256 rolesCount,
            address partnersInteractionNFTContract,
            uint256 numberOfActions
        ) = PartnersAgreement(_agreement).getAgreementData();

        require(agreementVersion < version, "already latest version");
        require(owner == msg.sender, "not agreement owner");        

        PartnersAgreement agreement = new PartnersAgreement(
            version,
            partnersContracts[0],
            msg.sender,
            communityAddress,
            rolesCount,
            numberOfActions,
            oracle,
            linkToken,
            partnersInteractionNFTContract
        );

        agreements[agreementId] = address(agreement);
        delete agreementIds[_agreement];
        agreementIds[address(agreement)] = agreementId;
    }
}
