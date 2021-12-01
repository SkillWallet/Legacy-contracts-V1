const { singletons, constants } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const { expect } = require('chai');
const { ethers } = require('hardhat');
const { ZERO_ADDRESS } = constants;

let partnersAgreement;
let membershipFactory;
let minimumCommunity;
let mockOracle;

contract('PartnersAgreement', function (accounts) {

  before(async function () {
    [signer, paOwner, coreTeamMember1, coreTeamMember2, coreTeamMember2, notACoreTeamMember, ...addrs] = await ethers.getSigners();
    erc1820 = await singletons.ERC1820Registry(signer.address);

    const LinkToken = await ethers.getContractFactory("LinkToken");
    const MockOracle = await ethers.getContractFactory("MockOracle");
    const SkillWallet = await ethers.getContractFactory("SkillWallet");
    const OffchainSignatureMechanism = await ethers.getContractFactory('OffchainSignatureMechanism');
    const MembershipFactory = await ethers.getContractFactory('MembershipFactory');
    const Membership = await ethers.getContractFactory('Membership');
    const MinimumCommunity = await ethers.getContractFactory('MinimumCommunity');
    const PartnersAgreement = await ethers.getContractFactory('PartnersAgreement');

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
    )

    partnersAgreement = await PartnersAgreement.deploy(
      membershipFactory.address,
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
      }
    );

    membership = await Membership.attach(await partnersAgreement.membershipAddress());
    const community = await MinimumCommunity.attach(partnersAgreement.communityAddress());
    await community.joinNewMember('', 1, 2000);
    await partnersAgreement.activatePA();

    const isActive = await partnersAgreement.isActive();
    assert.isTrue(isActive);

    await linkTokenMock.transfer(
      partnersAgreement.address,
      '2000000000000000000',
    )
  })
  describe('Create partners agreement', async function () {

    it("should deploy inactive partners agreement contract", async function () {
      const PartnersAgreement = await ethers.getContractFactory('PartnersAgreement');

      const pa = await PartnersAgreement.deploy(
        membershipFactory.address,
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
        }
      );

      await pa.deployed();
      const isActive = await pa.isActive();

      expect(pa.address).not.to.eq(ZERO_ADDRESS);
      expect(isActive).to.be.false;
    });

    it("should deploy and activate partners agreement contract", async function () {

      const PartnersAgreement = await ethers.getContractFactory('PartnersAgreement');

      const pa = await PartnersAgreement.deploy(
        membershipFactory.address,
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
        }
      );

      await pa.deployed();
      let isActive = await pa.isActive();

      expect(pa.address).not.to.eq(ZERO_ADDRESS);
      expect(isActive).to.be.false;

      await pa.activatePA();

      isActive = await pa.isActive();
      expect(isActive).to.be.true;

      const allUsers = await pa.getAllMembers();
      const interactionNFTAddress = await pa.getInteractionNFTContractAddress();

      expect(interactionNFTAddress).not.to.eq(ZERO_ADDRESS);
      expect(allUsers.length).to.eq(0);

    });
    it('should add new contract address if owner is the signer', async function () {

      console.log('isActive', await partnersAgreement.isActive());
      console.log('isCoreTeamMember', await partnersAgreement.isCoreTeamMember(signer.address));
      // const ownable = await OwnableTestContract.new({ from: accounts[1] });

      // await truffleAssert.reverts(
      //   this.partnersAgreement.addNewContractAddressToAgreement(this.skillWallet.address, { from: accounts[0] }),
      //   'Only the owner of the contract can import it!'
      // );

      // await truffleAssert.reverts(
      //   this.partnersAgreement.addNewContractAddressToAgreement(this.minimumCommunity.address),
      //   "Transaction reverted: function selector was not recognized and there's no fallback function"
      // );

      // await this.partnersAgreement.addNewContractAddressToAgreement(ownable.address, { from: accounts[0] });
      // console.log('isActive', await this.partnersAgreement.isActive());
      // const importedContracts = await this.partnersAgreement.getImportedAddresses();
      // assert.equal(importedContracts[0], ZERO_ADDRESS)
      // assert.equal(importedContracts[1], ownable.address)
    })
  });
  describe("Manage URLs", async () => {
    it("Should return false when URL list is empty", async () => {
      expect(await partnersAgreement.isURLListed("")).to.equal(false);
    });
    it("Should add an URL to the list", async () => {
      await partnersAgreement.addURL("https://test1.test");
      const urls = await partnersAgreement.getURLs();

      expect(await partnersAgreement.isURLListed("https://test1.test")).to.equal(true);
      expect(urls.length).to.equal(1);
      expect(urls[0]).to.equal("https://test1.test");
    });
    it("Should remove an URL from the list", async () => {
      await partnersAgreement.removeURL("https://test1.test");
      const urls = await partnersAgreement.getURLs();

      expect(await partnersAgreement.isURLListed("https://test1.test")).to.equal(false);
      expect(urls.length).to.equal(0);
    });
    it("Should add 3 more URLs to the list", async () => {
      await partnersAgreement.addURL("https://test1.test");
      await partnersAgreement.addURL("https://test2.test");
      await partnersAgreement.addURL("https://test3.test");
      const urls = await partnersAgreement.getURLs();

      expect(await partnersAgreement.isURLListed("https://test1.test")).to.equal(true);
      expect(await partnersAgreement.isURLListed("https://test2.test")).to.equal(true);
      expect(await partnersAgreement.isURLListed("https://test3.test")).to.equal(true);
      expect(urls.length).to.equal(3);
      expect(urls[0]).to.equal("https://test1.test");
      expect(urls[1]).to.equal("https://test2.test");
      expect(urls[2]).to.equal("https://test3.test");
    });
    it("Should not allow adding already existing URL to the list", async () => {
      await expect(partnersAgreement.addURL("https://test2.test")).to.be.revertedWith("url already exists");
    });
    it("Should return false when URL is not listed", async () => {
      expect(await partnersAgreement.isURLListed("https://test4.test")).to.equal(false);
      expect(await partnersAgreement.isURLListed("")).to.equal(false);
    });
    it("Should not allow removing of non existing URL", async () => {
      await expect(partnersAgreement.removeURL("https://test4.test")).to.be.revertedWith("url doesnt exist");
      await expect(partnersAgreement.removeURL("")).to.be.revertedWith("url doesnt exist");
    });
    it("Should remove one of the URLs from the list", async () => {
      await partnersAgreement.removeURL("https://test2.test");
      const urls = await partnersAgreement.getURLs();

      expect(await partnersAgreement.isURLListed("https://test1.test")).to.equal(true);
      expect(await partnersAgreement.isURLListed("https://test2.test")).to.equal(false);
      expect(await partnersAgreement.isURLListed("https://test3.test")).to.equal(true);
      expect(urls.length).to.equal(2);
      expect(urls[0]).to.equal("https://test1.test");
      expect(urls[1]).to.equal("https://test3.test");
    });
    it("Should remove last URLs from the list", async () => {
      await partnersAgreement.removeURL("https://test3.test");
      const urls = await partnersAgreement.getURLs();

      expect(await partnersAgreement.isURLListed("https://test1.test")).to.equal(true);
      expect(await partnersAgreement.isURLListed("https://test2.test")).to.equal(false);
      expect(await partnersAgreement.isURLListed("https://test3.test")).to.equal(false);
      expect(urls.length).to.equal(1);
      expect(urls[0]).to.equal("https://test1.test");
    });
    it("Should add one more URLs to the (end of) list", async () => {
      await partnersAgreement.addURL("https://test2.test");
      const urls = await partnersAgreement.getURLs();

      expect(await partnersAgreement.isURLListed("https://test1.test")).to.equal(true);
      expect(await partnersAgreement.isURLListed("https://test2.test")).to.equal(true);
      expect(await partnersAgreement.isURLListed("https://test3.test")).to.equal(false);
      expect(urls.length).to.equal(2);
      expect(urls[0]).to.equal("https://test1.test");
      expect(urls[1]).to.equal("https://test2.test");
    });
  });
  describe("Core team members", async () => {

    it("Should add owner as core team member after activation", async () => {
      const isActive = await partnersAgreement.isActive();
      const isCoreTeamMember = await partnersAgreement.isCoreTeamMember(signer.address);
      expect(isActive).to.be.true;
      expect(isCoreTeamMember).to.be.true;
    });
    it("Should succeed when the owner adds new core team members to the whitelist", async () => {
      await partnersAgreement.addNewCoreTeamMembers(coreTeamMember1.address);
      const teamMembers = await partnersAgreement.getCoreTeamMembers();
      expect(teamMembers.length).to.eq(2);
      expect(teamMembers[0]).to.eq(signer.address)
      expect(teamMembers[1]).to.eq(coreTeamMember1.address)
    });

    it("Should fail if the core team member hasn't created SW yet", async () => {
      expect(
        partnersAgreement.connect(coreTeamMember1).addNewCoreTeamMembers(coreTeamMember2.address)
      ).to.be.revertedWith("SkillWallet not created by the whitelisted member");
    });

    it("Should fail if the core team member hasn't created SW yet", async () => {
      expect(
        partnersAgreement.connect(coreTeamMember1).addNewCoreTeamMembers(coreTeamMember2.address)
      ).to.be.revertedWith("SkillWallet not created by the whitelisted member");
    });

    it("Should fail if unlisted core team member attepts to add other core team members", async () => {
      expect(
        partnersAgreement.connect(coreTeamMember2).addNewCoreTeamMembers(coreTeamMember2.address)
      ).to.be.revertedWith("SkillWallet not created by the whitelisted member");
    });
    it("Should fail if core team member spots are filled", async () => {
      await partnersAgreement.addNewCoreTeamMembers(coreTeamMember2.address);
      const coreTeamMembers = await partnersAgreement.getCoreTeamMembers();
      expect(
        partnersAgreement.addNewCoreTeamMembers(notACoreTeamMember.address)
      ).to.be.revertedWith("Core team member spots are filled.");
      expect(coreTeamMembers.length).to.eq(3);
      expect(coreTeamMembers[0]).to.eq(signer.address);
      expect(coreTeamMembers[1]).to.eq(coreTeamMember1.address);
      expect(coreTeamMembers[2]).to.eq(coreTeamMember2.address);
    });
  });
});
