const { expectEvent, singletons, constants } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const { expect } = require('chai');
const { ethers, artifacts } = require('hardhat');
const { ZERO_ADDRESS } = constants;
const truffleAssert = require('truffle-assertions')

const MinimumCommunity = artifacts.require('MinimumCommunity');
const MembershipFactory = artifacts.require('MembershipFactory');
const LinkToken = artifacts.require('LinkToken');
const MockOracle = artifacts.require('MockOracle');
const PartnersAgreement = artifacts.require('PartnersAgreement');
const Membership = artifacts.require('Membership');
const RoleUtils = artifacts.require('RoleUtils');
const InteractionNFT = artifacts.require('InteractionNFT');
const OwnableTestContract = artifacts.require('OwnableTestContract');
const SkillWallet = artifacts.require('skill-wallet/contracts/main/SkillWallet');
const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";
var BN = web3.utils.BN;

let partnersAgreement;

contract('PartnersAgreement', function (accounts) {
  before(async function () {
    this.erc1820 = await singletons.ERC1820Registry(accounts[1]);

    this.linkTokenMock = await LinkToken.new()
    this.mockOracle = await MockOracle.new(this.linkTokenMock.address)

    this.skillWallet = await SkillWallet.new(this.linkTokenMock.address, this.mockOracle.address);

    this.minimumCommunity = await MinimumCommunity.new(this.skillWallet.address);
    this.membershipFactory = await MembershipFactory.new(1);
    //this.roleUtils = await RoleUtils.new();

    //PartnersAgreement.link(this.roleUtils);

    this.partnersAgreement = await PartnersAgreement.new(
      1,
      ZERO_ADDRESS, // partners contract
      accounts[0],
      this.minimumCommunity.address,
      3,
      100,
      this.mockOracle.address,
      this.linkTokenMock.address,
      this.membershipFactory.address,
      ZERO_ADDRESS,
      ZERO_ADDRESS,
      { from: accounts[0] }
    );

    console.log(await this.partnersAgreement.membershipAddress());
    this.membership = await Membership.at(await this.partnersAgreement.membershipAddress());
    const community = await MinimumCommunity.at(await this.partnersAgreement.communityAddress());
    await community.joinNewMember('', 1, 2000);
    await this.partnersAgreement.activatePA();
    partnersAgreement = await ethers.getContractAt("PartnersAgreement", this.partnersAgreement.address);

    const isActive = await this.partnersAgreement.isActive();
    assert.isTrue(isActive);

    await this.linkTokenMock.transfer(
      this.partnersAgreement.address,
      '2000000000000000000',
    )

  });
  describe('Create partners agreement', async function () {

    it("should deploy inactive partners agreement contract", async function () {

      const partnersAgreement = await PartnersAgreement.new(
        1,
        ZERO_ADDRESS, // partners contract
        accounts[0],
        this.minimumCommunity.address,
        3,
        100,
        this.mockOracle.address,
        this.linkTokenMock.address,
        this.membershipFactory.address,
        ZERO_ADDRESS,
        ZERO_ADDRESS,
        { from: accounts[0] }
      );

      const isActive = await partnersAgreement.isActive();

      assert.notEqual(ZERO_ADDRESS, partnersAgreement.address);
      assert.isFalse(isActive);
    });


    it("should deploy and activate partners agreement contract", async function () {

      const partnersAgreement = await PartnersAgreement.new(
        1,
        ZERO_ADDRESS, // partners contract
        accounts[0],
        this.minimumCommunity.address,
        3,
        100,
        this.mockOracle.address,
        this.linkTokenMock.address,
        this.membershipFactory.address,
        ZERO_ADDRESS,
        ZERO_ADDRESS,
        { from: accounts[0] }
      );

      let isActive = await partnersAgreement.isActive();

      assert.notEqual(ZERO_ADDRESS, partnersAgreement.address);
      assert.isFalse(isActive);


      const community = await MinimumCommunity.at(await partnersAgreement.communityAddress());
      await partnersAgreement.activatePA();

      isActive = await partnersAgreement.isActive();
      assert.isTrue(isActive);

      const allUsers = await partnersAgreement.getAllMembers();
      const interactionNFTAddress = await partnersAgreement.getInteractionNFTContractAddress();
      //const profitSharing = await partnersAgreement.profitSharing();

      assert.notEqual(ZERO_ADDRESS, interactionNFTAddress);
      //assert.equal(ZERO_ADDRESS, profitSharing);
      assert.equal(0, allUsers);


    });

    it('transferInteractionNFTs should transfer the corrent amount of NFTs depending on the chainlink fulfilled request', async function () {
      await this.membership.create('', {from: accounts[0]});
      const initialInteractions = await this.partnersAgreement.getInteractionNFT(accounts[0]);
      assert.equal(initialInteractions.toString(), '0');

      let tx = await this.partnersAgreement.queryForNewInteractions(
        accounts[0]
      )
      let chainlinkRequestedEventEmitted =
        tx.logs[0].event === 'ChainlinkRequested'
      assert.isTrue(chainlinkRequestedEventEmitted)

      const requestId = tx.logs[0].args[0]
      const fulfilTx = await this.mockOracle.fulfillOracleRequest(
        requestId,
        10
      )

      const fulfilTxEventEmitted = fulfilTx.logs[0].event === 'CallbackCalled'
      assert.isTrue(fulfilTxEventEmitted)

      const interactions = await this.partnersAgreement.getInteractionNFT(accounts[0]);
      assert.equal(interactions.toString(), '10');
    })

    it('should add new contract address if owner is the signer', async function () {

      console.log('isActive', await this.partnersAgreement.isActive());
      console.log('isCoreTeamMember', await this.partnersAgreement.isCoreTeamMember(accounts[0]));
      const ownable = await OwnableTestContract.new({ from: accounts[1] });

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
});
