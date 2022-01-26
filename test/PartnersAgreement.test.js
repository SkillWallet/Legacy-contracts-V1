const { singletons, constants } = require('@openzeppelin/test-helpers');
const { assert, expect } = require('chai');
const { ethers } = require('hardhat');
const { ZERO_ADDRESS } = constants;

let partnersAgreement;
let minimumCommunity;
let mockOracle;
let interactionFactory;
let paOwner2Signee;

contract('PartnersAgreement', function (accounts) {

  before(async function () {
    [signer, paOwner, paOwner2, ...addrs] = await ethers.getSigners();
    // erc1820 = await singletons.ERC1820Registry(signer.address);
    paOwner2Signee = paOwner2;

    const LinkToken = await ethers.getContractFactory("LinkToken");
    const MockOracle = await ethers.getContractFactory("MockOracle");
    const SkillWallet = await ethers.getContractFactory("SkillWallet");
    const OffchainSignatureMechanism = await ethers.getContractFactory('OffchainSignatureMechanism');
    const MembershipFactory = await ethers.getContractFactory('MembershipFactory');
    const Membership = await ethers.getContractFactory('Membership');
    const MinimumCommunity = await ethers.getContractFactory('Community');
    const PartnersAgreement = await ethers.getContractFactory('PartnersAgreement');
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

    minimumCommunity = await MinimumCommunity.deploy(
      "url",
      1,
      100,
      signer.address,
      ZERO_ADDRESS,
      1,
      skillWallet.address,
      false,
      5,
      );


    await linkTokenMock.transfer(
      osmAddress,
      '2000000000000000000',
    );

    interactionFactory = await InteractionFactory.deploy();

    partnersAgreement = await PartnersAgreement.deploy(
      skillWallet.address,
      interactionFactory.address,
      {
        version: 1,
        owner: accounts[0],
        communityAddress: minimumCommunity.address,
        partnersContracts: [ZERO_ADDRESS],
        rolesCount: 3,
        interactionContract: ZERO_ADDRESS,
        interactionsCount: 100
      },
    );

    const community = await MinimumCommunity.attach(await partnersAgreement.communityAddress());
    await community.joinNewMember('', 1);
    await partnersAgreement.activatePA();

    assert.equal((await partnersAgreement.getAllMembers()).length, 1);

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
        skillWallet.address,
        interactionFactory.address,
        {
          version: 1,
          owner: accounts[0],
          communityAddress: minimumCommunity.address,
          partnersContracts: [ZERO_ADDRESS],
          rolesCount: 3,
          interactionContract: ZERO_ADDRESS,
          interactionsCount: 100,
        }
      );

      await pa.deployed();
      const isActive = await pa.isActive();

      expect(pa.address).not.to.eq(ZERO_ADDRESS);
      expect(isActive).to.be.false;
    });

    it.skip("should deploy and activate partners agreement contract", async function () {

      const PartnersAgreement = await ethers.getContractFactory('PartnersAgreement');

      const pa = await PartnersAgreement.connect(paOwner2Signee).deploy(
        skillWallet.address,
        interactionFactory.address,
        {
          version: 1,
          owner: accounts[0],
          communityAddress: minimumCommunity.address,
          partnersContracts: [ZERO_ADDRESS],
          rolesCount: 3,
          interactionContract: ZERO_ADDRESS,
          interactionsCount: 100,
        }
      );

      await pa.deployed();
      let isActive = await pa.isActive();

      const mems = await pa.getAllMembers();
      expect(mems.length).to.eq(0);
      expect(pa.address).not.to.eq(ZERO_ADDRESS);
      expect(isActive).to.be.false;

      const MinimumCommunity = await ethers.getContractFactory('Community');
      const c = await MinimumCommunity.attach(await pa.communityAddress());
      await (await c.connect(paOwner2Signee).joinNewMember('', 1)).wait();
      await pa.connect(paOwner2Signee).activatePA();

      isActive = await pa.isActive();
      expect(isActive).to.be.true;

      const allUsers = await pa.getAllMembers();
      const interactionNFTAddress = await pa.getInteractionNFTContractAddress();

      expect(interactionNFTAddress).not.to.eq(ZERO_ADDRESS);
      expect(allUsers.length).to.eq(1);

    });
    it('should add new contract address if owner is the signer', async function () {

      // const ownable = await OwnableTestContract.new({ from: accounts[1] });

      // await truffleAssert.reverts(
      //   partnersAgreement.addNewContractAddressToAgreement(skillWallet.address, { from: accounts[0] }),
      //   'Only the owner of the contract can import it!'
      // );

      // await truffleAssert.reverts(
      //   partnersAgreement.addNewContractAddressToAgreement(minimumCommunity.address),
      //   "Transaction reverted: function selector was not recognized and there's no fallback function"
      // );

      // await partnersAgreement.addNewContractAddressToAgreement(ownable.address, { from: accounts[0] });
      // console.log('isActive', await partnersAgreement.isActive());
      // const importedContracts = await partnersAgreement.getImportedAddresses();
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
});
