const { getContractFactory } = require('@nomiclabs/hardhat-ethers/types');
const { expectEvent, singletons, constants } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');
const { Contract } = require('ethers');
const { ZERO_ADDRESS } = constants;
const hre = require("hardhat");
const { ethers } = require("hardhat");

let factory;
let activities;

const URI = "https://hub.textile.io/ipfs/bafkreiaks3kjggtxqaj3ixk6ce2difaxj5r6lbemx5kcqdkdtub5vwv5mi";
const URI_FIN = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";


contract("Activities", (accounts) => {
    before(async () => {
        const Factory = await ethers.getContractFactory("ActivitiesFactory");
        factory = await Factory.deploy();
        await factory.deployed();
    });
    describe("Deployment", async () => {
        it("Should deploy activities contract", async () => {
            await factory.deployActivities(accounts[1]);

            const activitiesAddress = await factory.lastDeployedAddress();
            expect(activitiesAddress).not.to.equal(ZERO_ADDRESS);

            activities = await ethers.getContractAt("Activities", activitiesAddress);
            expect(await activities.partnersAgreement()).to.equal(accounts[0]);
            expect(await activities.botAddress()).to.equal(accounts[1]);
        });
    });
    describe("Activites", async () => {
        it("Should create some activities", async () => {
            await activities.createActivity(2, URI);
            await activities.createActivity(3, URI);
            await activities.createActivity(2, URI);

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
            await expect(activities.createActivity(0, URI)).to.be.reverted;
            await expect(activities.createActivity(1, URI)).to.be.reverted;
            await expect(activities.createActivity(4, URI)).to.be.reverted;
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
            await activities.createTask(URI, accounts[2]);
            await activities.createTask(URI, accounts[3]);

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
            await activities.takeTask(3, accounts[4]);

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
            await expect(activities.takeTask(3, accounts[5])).to.be.revertedWith("wrong status");
        });
        it("Should allow to finalize taken task", async () => {
            await activities.finilizeTask(3, accounts[4]);

            const task1 = await activities.getTaskByActivityId(3);

            expect(task1.activityId).to.equal("3");
            expect(task1.status).to.equal(2);
            expect(task1.creator).to.equal(accounts[2]);
            expect(task1.taker).to.equal(accounts[4]);

            expect(await activities.isFinalized(3)).to.equal(true);
        });
        it("Should not allow to finalze task that is not taken", async () => {
            await expect(activities.finilizeTask(4, accounts[3])).to.be.revertedWith("wrong status");
            await expect(activities.finilizeTask(3, accounts[4])).to.be.revertedWith("wrong status");
        });
        it("Should not allow to finalze task with not taker", async () => {
            await activities.takeTask(4, accounts[5]);

            await expect(activities.finilizeTask(4, accounts[3])).to.be.revertedWith("wrong taker");
        });
        it("Should not allow to take or finalize task that is not task (by type)", async () => {
            await expect(activities.takeTask(0, accounts[0])).to.be.revertedWith("Not core team task");
            await expect(activities.finilizeTask(0, accounts[0])).to.be.revertedWith("Not core team task");
        });
        it("Should not allow to finalize activity that is task (by type)", async () => {
            const bot = await ethers.getSigner(accounts[1]);
            const activitiesBot = await ethers.getContractAt("Activities", activities.address, bot);

            await expect(activitiesBot.finalizeActivity(4, URI_FIN)).to.be.revertedWith("activity doesnt exist");
        });
    });
});