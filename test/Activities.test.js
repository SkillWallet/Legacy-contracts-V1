const { constants } = require("@openzeppelin/test-helpers");
const { expect } = require("chai");
const { ZERO_ADDRESS } = constants;
const { ethers } = require("hardhat");

let activities;
let community;
let coreTeamMember1;
let coreTeamMember2;
let discordBotAddress;
let interactions;

const URI =
  "https://hub.textile.io/ipfs/bafkreiaks3kjggtxqaj3ixk6ce2difaxj5r6lbemx5kcqdkdtub5vwv5mi";
const URI_FIN =
  "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";
const metadataUrl =
  "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";

contract("Activities", (accounts) => {
  before(async () => {
    [
      signer,
      partner,
      notAMember,
      secondMember,
      coreTeam1,
      coreTeam2,
      discordBot,
      ...accounts
    ] = await ethers.getSigners();

    const SkillWallet = await ethers.getContractFactory("SkillWalletID");
    const skillWallet = await upgrades.deployProxy(SkillWallet, [
      "0x64307b67314b584b1E3Be606255bd683C835A876",
      "0x64307b67314b584b1E3Be606255bd683C835A876",
    ]);
    await skillWallet.deployed();

    memberAddress = signer;
    notACoreTeamMember = notAMember;
    partnerMember = partner;
    coreTeamMember1 = coreTeam1;
    coreTeamMember2 = coreTeam2;
    discordBotAddress = discordBot;

    const Community = await ethers.getContractFactory("Community");
    community = await Community.deploy(
      signer.address,
      "url",
      1,
      100,
      10,
      1,
      skillWallet.address,
      false,
      ZERO_ADDRESS
    );
    await community.deployed();

    await (
      await community
        .connect(memberAddress)
        .joinNewMember("http://someuri.co", 4)
    ).wait();

    // create skillwallets and add core team members
    await (
      await community
        .connect(memberAddress)
        .addNewCoreTeamMembers(coreTeam1.address)
    ).wait();
    await community.connect(coreTeam1).joinNewMember(metadataUrl, 4);

    //create skillwallets and add core team members
    await (
      await community
        .connect(memberAddress)
        .addNewCoreTeamMembers(coreTeam2.address)
    ).wait();
    await community.connect(coreTeam2).joinNewMember(metadataUrl, 4);

    //deploy activites factory
    const Activities = await ethers.getContractFactory("Activities");
    activities = await Activities.deploy(community.address, discordBot.address);
    await activities.deployed();

    const Interaction = await ethers.getContractFactory("Interaction");
    interactions = await Interaction.attach(
      await activities.getInteractionsAddr()
    );
  });
  describe.skip("Activites", async () => {
    it("Should create some activities", async () => {
      await activities.connect(memberAddress).createActivity(2, URI);
      await activities.connect(memberAddress).createActivity(3, URI);
      await activities.connect(memberAddress).createActivity(2, URI);

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
      await expect(activities.createActivity(4, URI)).to.be.reverted;
    });
    it("Should finalize some activities, set new URI and increase interaction indexers", async () => {
      await activities
        .connect(discordBotAddress)
        .finalizeActivity(1, URI_FIN, [
          coreTeamMember1.address,
          coreTeamMember2.address,
        ]);
      await activities
        .connect(discordBotAddress)
        .finalizeActivity(2, URI_FIN, [coreTeamMember1.address]);

      expect(await activities.connect(discordBotAddress).tokenURI(0)).to.equal(
        URI
      );
      expect(await activities.connect(discordBotAddress).tokenURI(1)).to.equal(
        URI_FIN
      );
      expect(await activities.connect(discordBotAddress).tokenURI(2)).to.equal(
        URI_FIN
      );

      expect(await activities.isFinalized(0)).to.equal(false);
      expect(await activities.isFinalized(1)).to.equal(true);
      expect(await activities.isFinalized(2)).to.equal(true);

      const interactionIndex =
        await interactions.getInteractionsIndexPerAddress(
          coreTeamMember1.address
        );
      expect(interactionIndex.toString()).to.equal("2");

      const interactionIndex2 =
        await interactions.getInteractionsIndexPerAddress(
          coreTeamMember2.address
        );
      expect(interactionIndex2.toString()).to.equal("1");
    });
    it("Should not allow change of URI once activity is finalized", async () => {
      await expect(
        activities.connect(discordBotAddress).finalizeActivity(1, URI, [])
      ).to.be.revertedWith("already finalized");
    });
  });
  describe.skip("Tasks", async () => {
    it("Should create some tasks", async () => {
      await activities.connect(coreTeamMember1).createTask(URI);
      await activities.connect(coreTeamMember2).createTask(URI);

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
      expect(task1.creator).to.equal(coreTeamMember1.address);
      expect(task1.taker).to.equal(ZERO_ADDRESS);

      expect(task2.activityId).to.equal("4");
      expect(task2.status).to.equal(0);
      expect(task2.creator).to.equal(coreTeamMember2.address);
      expect(task2.taker).to.equal(ZERO_ADDRESS);

      expect(await activities.tokenURI(3)).to.equal(URI);
      expect(await activities.tokenURI(4)).to.equal(URI);
    });
    it("Should take the task", async () => {
      await activities.connect(coreTeamMember2).takeTask(3);

      const task1 = await activities.getTaskByActivityId(3);
      const task2 = await activities.getTaskByActivityId(4);

      expect(task1.activityId).to.equal("3");
      expect(task1.status).to.equal(1);
      expect(task1.creator).to.equal(coreTeamMember1.address);
      expect(task1.taker).to.equal(coreTeamMember2.address);

      expect(task2.activityId).to.equal("4");
      expect(task2.status).to.equal(0);
      expect(task2.creator).to.equal(coreTeamMember2.address);
      expect(task2.taker).to.equal(ZERO_ADDRESS);
    });
    it("Should not allow to take task that is already taken", async () => {
      await expect(
        activities.connect(coreTeamMember2).takeTask(3)
      ).to.be.revertedWith("wrong status");
    });
    it("Should allow to finalize taken task", async () => {
      await activities.connect(coreTeamMember1).finilizeTask(3);
      const task1 = await activities.getTaskByActivityId(3);

      expect(task1.activityId).to.equal("3");
      expect(task1.status).to.equal(2);
      expect(task1.creator).to.equal(coreTeamMember1.address);
      expect(task1.taker).to.equal(coreTeamMember2.address);

      expect(await activities.isFinalized(3)).to.equal(true);

      const interactionIndex =
        await interactions.getInteractionsIndexPerAddress(task1.taker);
      expect(interactionIndex.toString()).to.equal("2");
    });
    it("Should not allow to finalze task that is not taken", async () => {
      await expect(
        activities.connect(coreTeamMember1).finilizeTask(3)
      ).to.be.revertedWith("wrong status");
      await expect(
        activities.connect(coreTeamMember2).finilizeTask(4)
      ).to.be.revertedWith("wrong status");
    });
    it("Should not allow the creator to take their task", async () => {
      await expect(
        activities.connect(coreTeamMember2).takeTask(4)
      ).to.be.revertedWith("Creator can't take the task");
    });
    it("Should not allow to take or finalize task that is not task (by type)", async () => {
      await expect(
        activities.connect(coreTeamMember1).takeTask(0)
      ).to.be.revertedWith("Not core team task");
      await expect(
        activities.connect(coreTeamMember1).finilizeTask(0)
      ).to.be.revertedWith("Not core team task");
    });
    it("Should not allow to finalize activity that is task (by type)", async () => {
      await expect(
        activities.connect(discordBotAddress).finalizeActivity(4, URI_FIN, [])
      ).to.be.revertedWith("activity doesnt exist");
    });
  });
});
