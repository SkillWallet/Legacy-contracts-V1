const { assert } = require('chai')
const truffleAssert = require('truffle-assertions')
const { constants } = require('@openzeppelin/test-helpers');
const { ethers, upgrades } = require('hardhat');
const { ZERO_ADDRESS } = constants;

let linkTokenMock;
let mockOracle;
let skillWallet;
let community;
let osmAddress;
let osm;

const metadataUrl =
  'https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice'

contract('SkillWallet', function () {

  beforeEach(async function () {
    [creator, communitySign, skillWalletOwner, ...addrs] = await ethers.getSigners();

    const LinkToken = await ethers.getContractFactory("LinkToken");
    const MockOracle = await ethers.getContractFactory("MockOracle");
    const SkillWallet = await ethers.getContractFactory("SkillWallet");
    const Community = await ethers.getContractFactory("Community");
    const OffchainSignatureMechanism = await ethers.getContractFactory('OffchainSignatureMechanism');

    linkTokenMock = await LinkToken.deploy();
    await linkTokenMock.deployed();

    mockOracle = await MockOracle.deploy(linkTokenMock.address);
    await mockOracle.deployed();

    skillWallet = await upgrades.deployProxy(
      SkillWallet,
      [linkTokenMock.address, mockOracle.address],
      { from: creator }
    );
    await skillWallet.deployed();


    osmAddress = await skillWallet.getOSMAddress();
    osm = await OffchainSignatureMechanism.attach(osmAddress);

    community = await Community.deploy(
      "url",
      1,
      100,
      creator.address,
      ZERO_ADDRESS,
      1,
      skillWallet.address,
      false,
      5
      );

    await community.deployed();

    await linkTokenMock.transfer(
      osmAddress,
      '2000000000000000000',
    )
  })

  describe('SkillWallet', async function () {
    describe('Creating a SkillWallet', async function () {
      it('should fail when there is already a SW to be claimed by this user', async function () {
        const tx = await (await skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const failingTx = skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )
        await truffleAssert.reverts(
          failingTx,
          'There is SkillWallet to be claimed by this address.',
        )
      })
      it('should fail when the user already owns a SW', async function () {
        const tx = await (await skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const claimedTx = await (await skillWallet.connect(skillWalletOwner).claim()).wait();
        const claimedTxEvent = claimedTx.events.find(e => e.event === 'SkillWalletClaimed');

        assert.isNotNull(claimedTxEvent)

        const failingTx = skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )
        await truffleAssert.reverts(
          failingTx,
          'SkillWallet: There is SkillWallet already registered for this address.',
        )
      })
      it('should fail when the user already owns a SW', async function () {
        const tx = await (await skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false
        )).wait()

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const failingTx1 = skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false
        )

        const failingTx2 = skillWallet.create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )
        await truffleAssert.reverts(
          failingTx1,
          'SkillWallet: There is SkillWallet already registered for this address.',
        )
        await truffleAssert.reverts(
          failingTx2,
          'SkillWallet: There is SkillWallet already registered for this address.',
        )
      })
      it('should create a claimable inactive SW', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)
        const tokenId = SWCreated.args[2].toString();

        const skillWalletClaimable = await skillWallet.isSkillWalletClaimable(
          skillWalletOwner.address,
        )
        const skillWalletId = await skillWallet.getClaimableSkillWalletId(
          skillWalletOwner.address
        )
        const skillWalletActiveCommunity = await skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletClaimable, true)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, communitySign.address)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], communitySign.address)
      })
      it('should create an inactive SW', async function () {

        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false,
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const tokenId = SWCreated.args[2].toString();

        const skillWalletClaimable = await skillWallet.isSkillWalletClaimable(
          skillWalletOwner.address,
        )
        const skillWalletId = await skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner.address
        )
        const skillWalletActiveCommunity = await skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletClaimable, false)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, communitySign.address)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], communitySign.address)
      })
      it('should claim SW and transfer the token to the owner', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const tokenId = SWCreated.args[2].toString();

        const skillWalletClaimable = await skillWallet.isSkillWalletClaimable(
          skillWalletOwner.address,
        )

        assert.equal(skillWalletClaimable, true)

        const claimedTx = await (await skillWallet.connect(skillWalletOwner).claim()).wait();

        const claimedTxEvent = claimedTx.events.find(e => e.event == 'SkillWalletClaimed');
        assert.isNotNull(claimedTxEvent);

        const owner = await skillWallet.ownerOf(
          tokenId
        );

        const skillWalletId = await skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner.address
        )
        const skillWalletActivated = await skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(owner, skillWalletOwner.address);
        assert.equal(skillWalletActivated, false)

      })
      it('should transfer the token to the owner if not claimable', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false,
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const tokenId = SWCreated.args[2].toString();

        const skillWalletClaimable = await skillWallet.isSkillWalletClaimable(
          skillWalletOwner.address,
        )

        assert.equal(skillWalletClaimable, false)

        const owner = await skillWallet.ownerOf(
          tokenId
        );

        const skillWalletId = await skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner.address
        )
        const skillWalletActivated = await skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(owner, skillWalletOwner.address);
        assert.equal(skillWalletActivated, false)

      })
      it('should fail claiming not claimable SW', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)

        const skillWalletClaimable = await skillWallet.isSkillWalletClaimable(
          skillWalletOwner.address,
        )

        assert.equal(skillWalletClaimable, false)

        const claimedTx = skillWallet.connect(skillWalletOwner).claim();

        await truffleAssert.reverts(
          claimedTx,
          'SkillWallet: There is SkillWallet already registered for this address.',
        )

      })
    })

    describe('Adding a pubKey to a SkillWallet', async function () {
      it('should fail when the SW is not created yet', async function () {
        const failingTx = skillWallet.connect(creator).addPubKeyToSkillWallet(1000000, '')
        await truffleAssert.reverts(
          failingTx,
          'SkillWallet: skillWalletId out of range.',
        )
      })
      it('should fail when the call is not made by the owner', async function () {
        const failingTx = skillWallet.connect(skillWalletOwner).addPubKeyToSkillWallet(1, '')
        await truffleAssert.reverts(
          failingTx,
          'Ownable: caller is not the owner',
        )
      })

      it('should fail when the SW has not been claimed yet.', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)
        const tokenId = SWCreated.args[2].toString();

        const failingTx = skillWallet.connect(creator).addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
        )

        await truffleAssert.reverts(
          failingTx,
          "SkillWallet: Skill wallet hasn't been claimed yet.",
        )
      })

      it('should fail when the SW has pubKey already assigned.', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false,
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)
        const tokenId = SWCreated.args[2].toString();

        const pubKeyTx = await (await skillWallet.connect(creator).addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
        )).wait();


        const pubKeyEventEmitted = pubKeyTx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(pubKeyEventEmitted)

        const failingTx = skillWallet.connect(creator).addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
        )

        await truffleAssert.reverts(
          failingTx,
          'SkillWallet: Skill wallet already has pubKey assigned.',
        )
      })

      it('should set pubKey properly', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          true,
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)
        const tokenId = SWCreated.args[2].toString();


        const claimedTx = await (await skillWallet.connect(skillWalletOwner).claim()).wait();
        const claimedTxEvent = claimedTx.events.find(e => e.event == 'SkillWalletCreated');

        assert.isNotNull(claimedTxEvent)

        const pubKeyTx = await (await skillWallet.connect(creator).addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
        )).wait();

        const pubKeyEventEmitted = pubKeyTx.events.find(e => e.event == 'SkillWalletCreated');

        assert.isNotNull(pubKeyEventEmitted)

        const skillWalletRegistered = await skillWallet.isSkillWalletRegistered(
          skillWalletOwner.address,
        )
        const skillWalletId = await skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner.address,
        )
        const skillWalletActiveCommunity = await skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await skillWallet.isSkillWalletActivated(
          tokenId,
        )

        const pubKey = await skillWallet.skillWalletToPubKey(tokenId)
        assert.equal(skillWalletRegistered, true)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, communitySign.address)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], communitySign.address)
        assert.equal(pubKey, 'pubKey')
      })

      it('should set pubKey properly', async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)
        const tokenId = SWCreated.args[2].toString();

        const pubKeyTx = await (await skillWallet.connect(creator).addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
        )).wait();

        const pubKeyEventEmitted = pubKeyTx.events.find(e => e.event == 'PubKeyAddedToSkillWallet');
        assert.isNotNull(pubKeyEventEmitted)

        const skillWalletRegistered = await skillWallet.isSkillWalletRegistered(
          skillWalletOwner.address,
        )
        const skillWalletId = await skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner.address,
        )
        const skillWalletActiveCommunity = await skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await skillWallet.isSkillWalletActivated(
          tokenId,
        )

        const pubKey = await skillWallet.skillWalletToPubKey(tokenId)
        assert.equal(skillWalletRegistered, true)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, communitySign.address)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], communitySign.address)
        assert.equal(pubKey, 'pubKey')
      })
    })

    describe('Activate skillWallet', async function () {

      let tokenId;
      beforeEach(async function () {
        const tx = await (await skillWallet.connect(communitySign).create(
          skillWalletOwner.address,
          metadataUrl,
          1,
          false
        )).wait();

        const SWCreated = tx.events.find(e => e.event == 'SkillWalletCreated');
        assert.isNotNull(SWCreated)
        tokenId = SWCreated.args[2].toString();

        // Add pubKey to the created SkillWallet
        const pubKeyTx = await (await skillWallet.connect(creator).addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
        )).wait();

        const pubKeyEventEmitted = pubKeyTx.events.find(e => e.event == 'PubKeyAddedToSkillWallet')

        assert.isNotNull(pubKeyEventEmitted)
      });

      it('should activate the SW if the response of the chainlink callback is true', async function () {
        const signature = ''
        const validationTx = await (await osm.validate(
          signature,
          tokenId,
          0,
          [],
          [],
          [],
        )).wait();

        const validationRequestIdSentEventEmitted =
          validationTx.events.find(e => e.event == 'ValidationRequestIdSent')
        
          const requestId = validationRequestIdSentEventEmitted.args[0];

        assert.isNotNull(validationRequestIdSentEventEmitted);

        const fulfilTx = await (await mockOracle["fulfillOracleRequest(bytes32,bool)"](
          requestId,
          true
        )).wait();

        const fulfilTxEventEmitted = fulfilTx.events.find(e => e.event == 'CallbackCalled')

        assert.isNotNull(fulfilTxEventEmitted);

        const isSWActivated = await skillWallet.isSkillWalletActivated(
          tokenId
        );

        assert.isTrue(isSWActivated)
      })
      it('should not activate the SW if the response of the chainlink callback is false', async function () {
        const signature = '';

        const validationTx = await (await osm.validate(
          signature,
          tokenId,
          0,
          [],
          [],
          [],
        )).wait();
        
        const validationRequestIdSentEventEmitted =
          validationTx.events.find(e => e.event == 'ValidationRequestIdSent')

        assert.isNotNull(validationRequestIdSentEventEmitted)
        const requestId = validationRequestIdSentEventEmitted.args[0]

        const fulfilTx = await (await mockOracle["fulfillOracleRequest(bytes32,bool)"](
          requestId,
          false
        )).wait();

        const fulfilTxEventEmitted = fulfilTx.events.find(e => e.event == 'CallbackCalled')

        assert.isNotNull(fulfilTxEventEmitted);

        const isSWActivated = await skillWallet.isSkillWalletActivated(
          tokenId
        );

        assert.isFalse(isSWActivated)
      })
    })
  })
})
