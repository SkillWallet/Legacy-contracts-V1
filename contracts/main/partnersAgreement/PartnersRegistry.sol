//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "./PartnersAgreement.sol";
import "../../imported/ICommunity.sol";
import "../../imported/IDistributedTown.sol";
import "../ISkillWallet.sol";

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";

contract PartnersRegistry is Initializable {

    event PartnersAgreementCreated(
        address partnersAgreementAddress,
        address communityAddress
    ); 
    IDistributedTown distributedTown;
    address[] agreements;
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
            partnersContractAddress,
            msg.sender,
            communityAddress,
            rolesCount,
            numberOfActions,
            oracle,
            linkToken
        );
        agreements.push(address(agreement));

        emit PartnersAgreementCreated(address(agreement), communityAddress);
    }
}
