const { getContractFactory } = require('@nomiclabs/hardhat-ethers/types');
const { expectEvent, singletons, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;
const { ethers } = require("hardhat");

let partnersRegistry;
let mockOracle;
let linkTokenMock;
let skillWallet;
let agreementAddress;

let contract1;
let contract2;

let com1Owner;
let com2Owner;
let com3Owner;

const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";

contract("PartnersRegistry", (accounts) => {
    before(async () => {
        [signer, com1, com2, com3, ...accounts] = await ethers.getSigners();

        com1Owner = await ethers.getSigner(com1.address);
        com2Owner = await ethers.getSigner(com2.address);
        com3Owner = await ethers.getSigner(com3.address);

        const LinkToken = await ethers.getContractFactory("LinkToken");
        linkTokenMock = await LinkToken.deploy();

        const MockOracle = await ethers.getContractFactory("MockOracle");
        mockOracle = await MockOracle.deploy(linkTokenMock.address);

        const SkillWallet = await ethers.getContractFactory("SkillWallet");
        skillWallet = await upgrades.deployProxy(
            SkillWallet,
            [linkTokenMock.address, mockOracle.address]
        );
        await skillWallet.deployed();
    });
    describe.only("Deployment", async () => {
        it("Should deploy Partners Registry contract", async () => {
            const PartnersRegistry = await ethers.getContractFactory("PartnersRegistry");
            const PartnersAgreementFactory = await ethers.getContractFactory("PartnersAgreementFactory");
            const MembershipFactory = await ethers.getContractFactory("MembershipFactory");
            const InteractionFactory = await ethers.getContractFactory("InteractionNFTFactory");

            const membershipFactory = await MembershipFactory.deploy(1);
            const interactionFactory = await InteractionFactory.deploy();
            const partnersAgreementFactory = await PartnersAgreementFactory.deploy(1, interactionFactory.address);

            partnersRegistry = await upgrades.deployProxy(
                PartnersRegistry,
                [
                    skillWallet.address,
                    partnersAgreementFactory.address,
                    membershipFactory.address,
                    accounts[3].address
                ]
            );
            await partnersRegistry.deployed();

            expect(partnersRegistry.address).not.to.equal(ZERO_ADDRESS);
        });
    });
    describe.only("New Partners Agreement", async () => {
        it("Should create new Partners Agreement", async () => {
            await partnersRegistry.connect(com1Owner).create(
                metadataUrl,
                1,
                2,
                100,
                ZERO_ADDRESS,
                10,
                3,
                false
            );

            agreementAddress = await partnersRegistry.agreements(0);
            const agreement = await ethers.getContractAt("PartnersAgreement", agreementAddress);
            const community = await ethers.getContractAt("Community", await agreement.communityAddress());
            await (await community.connect(com1Owner).joinNewMember('', 1)).wait();
            await agreement.connect(com1Owner).activatePA();
            const partnersContracts = await agreement.connect(com1Owner).getImportedAddresses();

            expect(agreementAddress).not.to.equal(ZERO_ADDRESS);
            expect(String(await partnersRegistry.agreementIds(agreementAddress))).to.equal("0");
            expect(String(await agreement.version())).to.equal("1");
            expect(partnersContracts.length).to.equal(1);
        });
        it("Should create 2 more agreements", async () => {
            const MockPartnersContract = await ethers.getContractFactory("MockPartnersContract");
            contract1 = await MockPartnersContract.connect(com2Owner).deploy();
            contract2 = await MockPartnersContract.connect(com3Owner).deploy();

            await partnersRegistry.connect(com2Owner).create(
                metadataUrl,
                1,
                2,
                100,
                contract1.address,
                10,
                3,
                false
            );

            const agreementAddress1 = await partnersRegistry.agreements(1);

            await partnersRegistry.connect(com3Owner).create(
                metadataUrl,
                1,
                2,
                100,
                contract2.address,
                10,
                3,
                false
            );

            const agreementAddress2 = await partnersRegistry.agreements(2);

            expect(agreementAddress1).not.to.equal(ZERO_ADDRESS);
            expect(String(await partnersRegistry.agreementIds(agreementAddress1))).to.equal("1");
            expect(agreementAddress2).not.to.equal(ZERO_ADDRESS);
            expect(String(await partnersRegistry.agreementIds(agreementAddress2))).to.equal("2");
        });
        it("Should have created PAs with unique partners contracts", async () => {
            const agreementAddress0 = await partnersRegistry.agreements(0);
            const agreementAddress1 = await partnersRegistry.agreements(1);
            const agreementAddress2 = await partnersRegistry.agreements(2);

            const agreement0 = await ethers.getContractAt("PartnersAgreement", agreementAddress0);
            const partnersContracts0 = await agreement0.getImportedAddresses();
            const agreement1 = await ethers.getContractAt("PartnersAgreement", agreementAddress1);
            const community1 = await ethers.getContractAt("Community", await agreement1.communityAddress());
            await (await community1.connect(com2Owner).joinNewMember('', 1)).wait();
            await agreement1.connect(com2Owner).activatePA();
            const partnersContracts1 = await agreement1.connect(com2Owner).getImportedAddresses();
            const agreement2 = await ethers.getContractAt("PartnersAgreement", agreementAddress2);
            const community2 = await ethers.getContractAt("Community", await agreement2.communityAddress());
            await (await community2.connect(com3Owner).joinNewMember('', 1)).wait();
            await agreement2.connect(com3Owner).activatePA();
            const partnersContracts2 = await agreement2.connect(com3Owner).getImportedAddresses();

            expect(partnersContracts0.length).to.equal(1);
            expect(partnersContracts1.length).to.equal(1);
            expect(partnersContracts2.length).to.equal(1);

            expect(partnersContracts1[0]).to.equal(contract1.address);
            expect(partnersContracts2[0]).to.equal(contract2.address);
        });
    });
    describe.only("Partners Agreement Migrations", async () => {
        it("Should migrate new Partners Agreement", async () => {
            await (await partnersRegistry.setVersion(2)).wait();

            const oldAgreement = await ethers.getContractAt("PartnersAgreement", agreementAddress);
            const oldData = await oldAgreement.connect(com1Owner).getAgreementData();

            await partnersRegistry.connect(com1Owner).migrate(agreementAddress);

            const newAgreementAddress = await partnersRegistry.agreements(0);
            const agreement = await ethers.getContractAt("PartnersAgreement", newAgreementAddress);
            const newData = await agreement.connect(com1Owner).getAgreementData();

            expect(oldData.owner).to.equal(newData.owner);
            expect(newAgreementAddress).not.to.equal(ZERO_ADDRESS);
            expect(oldData.rolesCount).to.equal(newData.rolesCount);
            expect(newAgreementAddress).not.to.equal(agreementAddress);
            expect(oldData.communityAddress).to.equal(newData.communityAddress);
            expect(oldData.interactionsCount).to.equal(newData.interactionsCount);
            expect(oldData.membershipContract).to.equal(newData.membershipContract);
            expect(oldData.interactionContract).to.equal(newData.interactionContract);
            expect(oldData.interactionsQueryServer).to.equal(newData.interactionsQueryServer);
            expect(String(await partnersRegistry.agreementIds(newAgreementAddress))).to.equal("0");
            expect(String(await agreement.version())).to.equal("2");
        });
    });
});