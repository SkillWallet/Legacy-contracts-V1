const { getContractFactory } = require('@nomiclabs/hardhat-ethers/types');
const { expectEvent, singletons, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { Contract } = require('ethers');
const { ZERO_ADDRESS } = constants;
const hre = require("hardhat");
const { ethers } = require("hardhat");

let factory;
let activities;
let agreement;
let community;

const URI = "https://hub.textile.io/ipfs/bafkreiaks3kjggtxqaj3ixk6ce2difaxj5r6lbemx5kcqdkdtub5vwv5mi";
const URI_FIN = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";
const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";

contract("Activities", (accounts) => {
    before(async () => {
        //deploy prerequisites
        const LinkToken = await ethers.getContractFactory("LinkToken");
        const linkTokenMock = await LinkToken.deploy();

        const MockOracle = await ethers.getContractFactory("MockOracle");
        const mockOracle = await MockOracle.deploy(linkTokenMock.address);

        const SkillWallet = await ethers.getContractFactory("SkillWalletID");
        const skillWallet = await upgrades.deployProxy(
            SkillWallet,
            [linkTokenMock.address, mockOracle.address]
        );
        await skillWallet.deployed();

        //deploy pr
        const InteractionFactory = await ethers.getContractFactory("InteractionNFTFactory");
        const PartnersRegistry = await ethers.getContractFactory("PartnersRegistry");
        const PartnersAgreementFactory = await ethers.getContractFactory("PartnersAgreementFactory");
        const CommunityRegistry = await ethers.getContractFactory('CommunityRegistry');

        const interactionFactory = await InteractionFactory.deploy();

        const partnersRegistry = await upgrades.deployProxy(
            PartnersRegistry,
            [
                skillWallet.address,
                interactionFactory.address,
            ]
        );
        await partnersRegistry.deployed();

        communityRegistry = await upgrades.deployProxy(
            CommunityRegistry,
            [skillWallet.address]
          );
        await communityRegistry.deployed();

        const com = await (await communityRegistry.createCommunity(
            '',
            1,
            100,
            10,
            false,
            ZERO_ADDRESS
          )).wait();

        //deploy pa
        await partnersRegistry.create(
            com.events[0].args['comAddr'],
            3,
            5,
            ZERO_ADDRESS,
        );

        //TODO: Milena!
        const agreementAddress = await partnersRegistry.agreements(0);
        agreement = await ethers.getContractAt("PartnersAgreement", agreementAddress);
        const communityAddress = await agreement.communityAddress();
        community = await ethers.getContractAt('Community', communityAddress);
        await community.joinNewMember('url', 1);


        //create skillwallets and add core team members
        for (let i = 2; i <= 5; i++) {
            const coreTM = await ethers.getSigner(accounts[i]);

            await community.connect(coreTM).joinNewMember(
                metadataUrl,
                1,
            );

            await community.addNewCoreTeamMembers(accounts[i]);

        }

        //deploy activites factory
        const Factory = await ethers.getContractFactory("ActivitiesFactory");
        factory = await Factory.deploy();
        await factory.deployed();

        console.log('asdasdasd')
    });
    describe("Deployment", async () => {
        it("Should deploy activities contract", async () => {

            await agreement.deployActivities(factory.address);

            const activitiesAddress = await agreement.activities();
            expect(activitiesAddress).not.to.equal(ZERO_ADDRESS);

            const interactionAddress = await agreement.interactionNFT();
            expect(interactionAddress).not.to.equal(ZERO_ADDRESS);

            activities = await ethers.getContractAt("Activities", activitiesAddress);
            expect(await activities.partnersAgreement()).to.equal(agreement.address);
        });
    });
    describe("Activites", async () => {
        it("Should create some activities", async () => {
            await agreement.createActivity(2, URI);
            await agreement.createActivity(3, URI);
            await agreement.createActivity(2, URI);

            const polls = await activities.getActivitiesByType(2);
            const calls = await activities.getActivitiesByType(3);
            const tasks = await activities.getActivitiesByType(1);

            expect(polls.length).to.equal(2);
            expect(calls.length).to.equal(1);
            expect(tasks.length).to.equal(0);

            expect(polls[0]).to.equal(0);
            expect(polls[1]).to.equal(2);
            expect(calls[0]).to.equal(1);
        });
        it("Should not allow to create activity with wong type", async () => {
            await expect(agreement.createActivity(0, URI)).to.be.reverted;
            await expect(agreement.createActivity(4, URI)).to.be.reverted;
        });
        it("Should finalize some activities and set new URI", async () => {
            const bot = await ethers.getSigner(accounts[1]);
            const activitiesBot = await ethers.getContractAt("Activities", activities.address, bot);

            await activitiesBot.finalizeActivity(1, URI_FIN);
            await activitiesBot.finalizeActivity(2, URI_FIN);

            expect(await activities.tokenURI(0)).to.equal(URI);
            expect(await activities.tokenURI(1)).to.equal(URI_FIN);
            expect(await activities.tokenURI(2)).to.equal(URI_FIN);

            expect(await activities.isFinalized(0)).to.equal(false);
            expect(await activities.isFinalized(1)).to.equal(true);
            expect(await activities.isFinalized(2)).to.equal(true);
        });
        it("Should not allow change of URI once activity is finalized", async () => {
            const bot = await ethers.getSigner(accounts[1]);
            const activitiesBot = await ethers.getContractAt("Activities", activities.address, bot);

            await expect(activitiesBot.finalizeActivity(1, URI)).to.be.revertedWith("already finalized");
        });
    });
    describe("Tasks", async () => {
        it("Should create some tasks", async () => {
            const teamMember1 = await ethers.getSigner(accounts[2]);
            const teamMember2 = await ethers.getSigner(accounts[3]);
            const agreementTM1 = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember1);
            const agreementTM2 = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember2);

            await agreementTM1.createActivity(1, URI);
            await agreementTM2.createActivity(1, URI);

            const polls = await activities.getActivitiesByType(2);
            const calls = await activities.getActivitiesByType(3);
            const tasks = await activities.getActivitiesByType(1);

            expect(polls.length).to.equal(2);
            expect(calls.length).to.equal(1);
            expect(tasks.length).to.equal(2);

            expect(polls[0]).to.equal(0);
            expect(polls[1]).to.equal(2);
            expect(calls[0]).to.equal(1);
            expect(tasks[0]).to.equal(3);
            expect(tasks[1]).to.equal(4);
        });
        it("Should have stored task details", async () => {
            const task1 = await activities.tasks(0);
            const task2 = await activities.tasks(1);

            expect(await activities.activityToTask(3)).to.equal("0");
            expect(await activities.activityToTask(4)).to.equal("1");

            expect(task1.activityId).to.equal("3");
            expect(task1.status).to.equal(0);
            expect(task1.creator).to.equal(accounts[2]);
            expect(task1.taker).to.equal(ZERO_ADDRESS);

            expect(task2.activityId).to.equal("4");
            expect(task2.status).to.equal(0);
            expect(task2.creator).to.equal(accounts[3]);
            expect(task2.taker).to.equal(ZERO_ADDRESS);

            expect(await activities.tokenURI(3)).to.equal(URI);
            expect(await activities.tokenURI(4)).to.equal(URI);
        });
        it("Should take the task", async () => {
            const teamMember = await ethers.getSigner(accounts[4]);
            const agreementTM = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember);

            await agreementTM.takeTask(3);

            const task1 = await activities.getTaskByActivityId(3);
            const task2 = await activities.getTaskByActivityId(4);

            expect(task1.activityId).to.equal("3");
            expect(task1.status).to.equal(1);
            expect(task1.creator).to.equal(accounts[2]);
            expect(task1.taker).to.equal(accounts[4]);

            expect(task2.activityId).to.equal("4");
            expect(task2.status).to.equal(0);
            expect(task2.creator).to.equal(accounts[3]);
            expect(task2.taker).to.equal(ZERO_ADDRESS);
        });
        it("Should not allow to take task that is already taken", async () => {
            const teamMember = await ethers.getSigner(accounts[5]);
            const agreementTM = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember);

            await expect(agreementTM.takeTask(3)).to.be.revertedWith("wrong status");
        });
        it("Should allow to finalize taken task", async () => {
            const teamMember = await ethers.getSigner(accounts[4]);
            const agreementTM = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember);
            const intNFT = await agreementTM.interactionNFT();
            const interactionNFT = await ethers.getContractAt("InteractionNFT", intNFT, teamMember);

            await agreementTM.finilizeTask(3);

            const task1 = await activities.getTaskByActivityId(3);

            expect(task1.activityId).to.equal("3");
            expect(task1.status).to.equal(2);
            expect(task1.creator).to.equal(accounts[2]);
            expect(task1.taker).to.equal(accounts[4]);

            expect(await activities.isFinalized(3)).to.equal(true);
            const intNFTBalanceTaker = await interactionNFT.balanceOf(task1.taker, 1);
            expect(intNFTBalanceTaker.toString()).to.equal('1');
        });
        it("Should not allow to finalze task that is not taken", async () => {
            const teamMember1 = await ethers.getSigner(accounts[3]);
            const teamMember2 = await ethers.getSigner(accounts[4]);
            const agreementTM1 = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember1);
            const agreementTM2 = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember2);

            await expect(agreementTM1.finilizeTask(4)).to.be.revertedWith("wrong status");
            await expect(agreementTM2.finilizeTask(3)).to.be.revertedWith("wrong status");
        });
        it("Should not allow to finalze task with not taker", async () => {
            const teamMember1 = await ethers.getSigner(accounts[5]);
            const teamMember2 = await ethers.getSigner(accounts[3]);
            const agreementTM1 = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember1);
            const agreementTM2 = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember2);

            await agreementTM1.takeTask(4);

            await expect(agreementTM2.finilizeTask(4)).to.be.revertedWith("wrong taker");
        });
        it("Should not allow to take or finalize task that is not task (by type)", async () => {
            const teamMember = await ethers.getSigner(accounts[0]);
            const agreementTM = await ethers.getContractAt("PartnersAgreement", agreement.address, teamMember);

            await expect(agreementTM.takeTask(0)).to.be.revertedWith("Not core team task");
            await expect(agreementTM.finilizeTask(0)).to.be.revertedWith("Not core team task");
        });
        it("Should not allow to finalize activity that is task (by type)", async () => {
            const bot = await ethers.getSigner(accounts[1]);
            const activitiesBot = await ethers.getContractAt("Activities", activities.address, bot);

            await expect(activitiesBot.finalizeActivity(4, URI_FIN)).to.be.revertedWith("activity doesnt exist");
        });
    });
});