const { singletons, constants } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { ZERO_ADDRESS } = constants;

const ADDRESS_FIELD = '0x11111111111110000000000000000000000000fF';
const STRING_FIELD = 'test';
const UINT_FIELD = 123;

let partnersAgreement;
let membershipFactory;
let minimumCommunity;
let mockOracle;
let interactionFactory;

contract ('PartnersAgreementAddFields', (accounts) => {
    describe('Test PA with additional fields' , async() => {
        before(async() => {
            [signer, paOwner, coreTeamMember1, coreTeamMember2, coreTeamMember2, notACoreTeamMember, ...addrs] = await ethers.getSigners();
            erc1820 = await singletons.ERC1820Registry(signer.address);
        
            const LinkToken = await ethers.getContractFactory("LinkToken");
            const MockOracle = await ethers.getContractFactory("MockOracle");
            const SkillWallet = await ethers.getContractFactory("SkillWallet");
            const OffchainSignatureMechanism = await ethers.getContractFactory('OffchainSignatureMechanism');
            const MembershipFactory = await ethers.getContractFactory('MembershipFactory');
            const Membership = await ethers.getContractFactory('Membership');
            const MinimumCommunity = await ethers.getContractFactory('MinimumCommunity');
            
            const InteractionFactory = await ethers.getContractFactory("InteractionNFTFactory");
        
            linkTokenMock = await LinkToken.deploy();
            await linkTokenMock.deployed();
        
            mockOracle = await MockOracle.deploy(linkTokenMock.address);
            await mockOracle.deployed();
        
            skillWallet = await upgrades.deployProxy(
              SkillWallet,
              [linkTokenMock.address, mockOracle.address],
            );
            await skillWallet.deployed();
        
            osmAddress = await skillWallet.getOSMAddress();
            osm = await OffchainSignatureMechanism.attach(osmAddress);
        
            minimumCommunity = await MinimumCommunity.deploy(skillWallet.address);
        
            membershipFactory = await MembershipFactory.deploy(1);
        
            await linkTokenMock.transfer(
              osmAddress,
              '2000000000000000000',
            );
        
            interactionFactory = await InteractionFactory.deploy();
        });

        it("Should create PA with additional fileds", async() => {
            const PartnersAgreement = await ethers.getContractFactory('PartnersAgreementAddFields');

            const additionalUint = ethers.utils.hexZeroPad(ethers.utils.hexlify(UINT_FIELD), 32)
            const additionalAddress = ethers.utils.hexZeroPad(ethers.utils.hexlify(ADDRESS_FIELD), 32);

            partnersAgreement = await PartnersAgreement.deploy(
                membershipFactory.address,
                interactionFactory.address,
                {
                    version: 1,
                    owner: accounts[0],
                    communityAddress: minimumCommunity.address,
                    partnersContracts: [ZERO_ADDRESS],
                    rolesCount: 3,
                    interactionContract: ZERO_ADDRESS,
                    membershipContract: ZERO_ADDRESS,
                    interactionsCount: 100,
                    coreTeamMembersCount: 3,
                    whitelistedTeamMembers: [ZERO_ADDRESS],
                    interactionsQueryServer: accounts[3]
                },
                [additionalUint, additionalAddress],
                [STRING_FIELD]
            );

            expect((await partnersAgreement.additionalFieldUint()).toNumber()).to.equal(UINT_FIELD);
            expect(await partnersAgreement.additionalFieldAddress()).to.equal(ADDRESS_FIELD);
            expect(await partnersAgreement.additionalFieldString()).to.equal(STRING_FIELD);
        });

        it("Should call additional fields getter and use result to create new PA", async() => {
            const PartnersAgreement = await ethers.getContractFactory('PartnersAgreementAddFields');

            const fields = await partnersAgreement.getAdditionalFields();

            const partnersAgreementNew = await PartnersAgreement.deploy(
                membershipFactory.address,
                interactionFactory.address,
                {
                    version: 1,
                    owner: accounts[0],
                    communityAddress: minimumCommunity.address,
                    partnersContracts: [ZERO_ADDRESS],
                    rolesCount: 3,
                    interactionContract: ZERO_ADDRESS,
                    membershipContract: ZERO_ADDRESS,
                    interactionsCount: 100,
                    coreTeamMembersCount: 3,
                    whitelistedTeamMembers: [ZERO_ADDRESS],
                    interactionsQueryServer: accounts[3]
                },
                [fields[0][0], fields[0][1]],
                [fields[1][0]]
            );

            expect((await partnersAgreementNew.additionalFieldUint()).toNumber()).to.equal(UINT_FIELD);
            expect(await partnersAgreementNew.additionalFieldAddress()).to.equal(ADDRESS_FIELD);
            expect(await partnersAgreementNew.additionalFieldString()).to.equal(STRING_FIELD);
        });
    });
});