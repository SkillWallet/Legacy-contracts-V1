//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "../interfaces/IPartnersRegistry.sol";
import "../contracts/PartnersAgreement.sol";

import "../../../imported/CommonTypes.sol";
import "../../community/ICommunity.sol";

contract PartnersRegistry is IPartnersRegistry, Initializable {
    //versioning
    uint256 public version;
    address public deployer;

    // agreements
    address[] public agreements;
    mapping(address => uint256) public agreementIds;

    // factories
    address public interactionNFTFactory;
    address public skillWalletAddress;

    function initialize(
        address _skillWalletAddress,
        address _interactionNFTFactory
    ) public initializer {
        skillWalletAddress = _skillWalletAddress;
        interactionNFTFactory = _interactionNFTFactory;

        version = 1;
        deployer = msg.sender;
    }

    function setVersion(uint256 _version) public override {
        require(msg.sender == deployer, "Only deployer can set verison");
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
        address communityAddress,
        uint256 rolesCount,
        uint256 commitmentLevel,
        address partnersContractAddress
    ) public override {
        require(
            commitmentLevel > 0 && commitmentLevel <= 10,
            "CommitmentLevel should be between 1 and 10"
        );

        require(
            ICommunity(communityAddress).owner() == msg.sender,
            "Only owner can attach community to PA"
        );

        if (partnersContractAddress == address(0))
            partnersContractAddress = communityAddress;

        address[] memory contracts;

        address paAddr = address(
            new PartnersAgreement(
                skillWalletAddress,
                interactionNFTFactory,
                Types.PartnersAgreementData(
                    version,
                    msg.sender,
                    communityAddress,
                    contracts,
                    rolesCount,
                    address(0),
                    commitmentLevel
                )
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

        address agreement = address(
            new PartnersAgreement(skillWalletAddress, interactionNFTFactory, pa)
        );
        agreements[agreementId] = agreement;
        delete agreementIds[_agreement];
        agreementIds[agreement] = agreementId;
    }
}
