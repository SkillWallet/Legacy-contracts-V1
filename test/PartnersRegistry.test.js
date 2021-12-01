const { getContractFactory } = require('@nomiclabs/hardhat-ethers/types');
const { expectEvent, singletons, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { ZERO_ADDRESS } = constants;
const { ethers } = require("hardhat");

let partnersRegistry;
let mockOracle;
let linkTokenMock;
let skillWallet;
let minimumCommunity;
let distributedTownMock;
let agreementAddress;

const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";

contract("PartnersRegistry", (accounts) => {
    before(async () => {
        const LinkToken = await ethers.getContractFactory("LinkToken");
        linkTokenMock = await LinkToken.deploy();

        const MockOracle = await ethers.getContractFactory("MockOracle");
        mockOracle = await MockOracle.deploy(linkTokenMock.address);

        const DistributedTownMock = await ethers.getContractFactory("DistributedTownMock");
        distributedTownMock = await DistributedTownMock.deploy();

        const SkillWallet = await ethers.getContractFactory("SkillWallet");
        skillWallet = await upgrades.deployProxy(
            SkillWallet,
            [linkTokenMock.address, mockOracle.address]
        );
        await skillWallet.deployed();

        const MinimumCommunity = await ethers.getContractFactory("MinimumCommunity");
        minimumCommunity = await MinimumCommunity.deploy(skillWallet.address);
        await minimumCommunity.joinNewMember('', 1, 2000);
        await distributedTownMock.addCommunity(accounts[0], minimumCommunity.address);
    });
    describe("Deployment", async () => {
        it("Should deploy Partners Registry contract", async () => {
            const PartnersRegistry = await ethers.getContractFactory("PartnersRegistry");
            const PartnersAgreementFactory = await ethers.getContractFactory("PartnersAgreementFactory");
            const MembershipFactory = await ethers.getContractFactory("MembershipFactory");

            const membershipFactory = await MembershipFactory.deploy(1);
            const partnersAgreementFactory = await PartnersAgreementFactory.deploy(1);

            partnersRegistry = await upgrades.deployProxy(
                PartnersRegistry,
                [distributedTownMock.address,
                partnersAgreementFactory.address,
                membershipFactory.address,
                mockOracle.address,
                linkTokenMock.address]
            );
            await partnersRegistry.deployed();

            expect(partnersRegistry.address).not.to.equal(ZERO_ADDRESS);
        });
    });
    describe("New Partners Agreement", async () => {
        it("Should create new Partners Agreement", async () => {
            await partnersRegistry.create(
                metadataUrl,
                1,
                2,
                100,
                ZERO_ADDRESS,
                10,
                3
            );

            agreementAddress = await partnersRegistry.agreements(0);
            console.log(agreementAddress);
            const agreement = await ethers.getContractAt("PartnersAgreement", agreementAddress);
            await agreement.activatePA();

            expect(agreementAddress).not.to.equal(ZERO_ADDRESS);
            expect(String(await partnersRegistry.agreementIds(agreementAddress))).to.equal("0");
            expect(String(await agreement.version())).to.equal("1");
        });
        it("Should create 2 more agreements", async () => {
            await partnersRegistry.create(
                metadataUrl,
                1,
                2,
                100,
                ZERO_ADDRESS,
                10,
                3
            );

            const agreementAddress1 = await partnersRegistry.agreements(1);

            await partnersRegistry.create(
                metadataUrl,
                1,
                2,
                100,
                ZERO_ADDRESS,
                10,
                3
            );

            const agreementAddress2 = await partnersRegistry.agreements(2);

            expect(agreementAddress1).not.to.equal(ZERO_ADDRESS);
            expect(String(await partnersRegistry.agreementIds(agreementAddress1))).to.equal("1");
            expect(agreementAddress2).not.to.equal(ZERO_ADDRESS);
            expect(String(await partnersRegistry.agreementIds(agreementAddress2))).to.equal("2");
        });
    });
    describe("Partners Agreement Migrations", async () => {
        it("Should migrate new Partners Agreement", async () => {
            await (await partnersRegistry.setVersion(2)).wait();
            
            const oldAgreement = await ethers.getContractAt("PartnersAgreement", agreementAddress);
            const oldData = await oldAgreement.getAgreementData();

            await partnersRegistry.migrate(agreementAddress);

            const newAgreementAddress = await partnersRegistry.agreements(0);
            const agreement = await ethers.getContractAt("PartnersAgreement", newAgreementAddress);
            const newData = await agreement.getAgreementData();

            expect(oldData.owner).to.equal(newData.owner);
            expect(newAgreementAddress).not.to.equal(ZERO_ADDRESS);
            expect(oldData.rolesCount).to.equal(newData.rolesCount);
            expect(newAgreementAddress).not.to.equal(agreementAddress);
            expect(oldData.communityAddress).to.equal(newData.communityAddress);
            expect(oldData.interactionsCount).to.equal(newData.interactionsCount);
            expect(oldData.membershipContract).to.equal(newData.membershipContract);
            expect(oldData.interactionContract).to.equal(newData.interactionContract);
            expect(oldData.coreTeamMembersCount).to.equal(newData.coreTeamMembersCount);
            expect(oldData.whitelistedTeamMembers.length).to.equal(newData.whitelistedTeamMembers.length);
            expect(String(await partnersRegistry.agreementIds(newAgreementAddress))).to.equal("0");
            expect(String(await agreement.version())).to.equal("2");
        });
    });
});