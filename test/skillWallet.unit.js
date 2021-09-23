const { assert } = require('chai')
const truffleAssert = require('truffle-assertions')

const Community = artifacts.require('MinimumCommunity')
const SkillWallet = artifacts.require('SkillWallet')
const MockOracle = artifacts.require('MockOracle')
const LinkToken = artifacts.require('LinkToken')
const metadataUrl =
  'https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice'
var BN = web3.utils.BN
const { expect } = require('chai')

contract('SkillWallet', function ([_, community, creator, skillWalletOwner]) {
  before(async function () { })
  beforeEach(async function () {
    this.linkTokenMock = await LinkToken.new()
    this.mockOracle = await MockOracle.new(this.linkTokenMock.address)
    this.skillWallet = await SkillWallet.new(
      this.linkTokenMock.address,
      this.mockOracle.address,
      { from: creator },
    )
    this.community = await Community.new(this.skillWallet.address)
  })

  describe('SkillWallet', async function () {
    describe('Creating a SkillWallet', async function () {
      it('should fail when there is already a SW to be claimed by this user', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true
        )

        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        assert.equal(SWCreated, true)

        const failingTx = this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true
        )
        await truffleAssert.reverts(
          failingTx,
          'There is SkillWallet to be claimed by this address.',
        )
      })
      it('should fail when the user already owns a SW', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true
        )

        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        assert.equal(SWCreated, true)

        const claimedTx = await this.skillWallet.claim({ from: skillWalletOwner });
        const claimedTxEvent = claimedTx.logs[2].event === 'SkillWalletClaimed'

        assert.equal(claimedTxEvent, true)

        const failingTx = this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true
        )
        await truffleAssert.reverts(
          failingTx,
          'SkillWallet: There is SkillWallet already registered for this address.',
        )
      })
      it('should fail when the user already owns a SW', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          false
        )

        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        assert.equal(SWCreated, true)

        const failingTx1 = this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          false
        )

        const failingTx2 = this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
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
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const skillWalletClaimable = await this.skillWallet.isSkillWalletClaimable(
          skillWalletOwner,
        )
        const skillWalletId = await this.skillWallet.getClaimableSkillWalletId(
          skillWalletOwner
        )
        const skillWalletActiveCommunity = await this.skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await this.skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletClaimable, true)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, community)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], community)
      })
      it('should create an inactive SW', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          false,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const skillWalletClaimable = await this.skillWallet.isSkillWalletClaimable(
          skillWalletOwner,
        )
        const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner
        )
        const skillWalletActiveCommunity = await this.skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await this.skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletClaimable, false)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, community)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], community)
      })
      it('should claim SW and transfer the token to the owner', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const skillWalletClaimable = await this.skillWallet.isSkillWalletClaimable(
          skillWalletOwner,
        )

        assert.equal(skillWalletClaimable, true)

        const claimedTx = await this.skillWallet.claim({ from: skillWalletOwner });
        const claimedTxEvent = claimedTx.logs[2].event === 'SkillWalletClaimed'

        assert.equal(claimedTxEvent, true);

        const owner = await this.skillWallet.ownerOf(
          tokenId
        );

        const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner
        )
        const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(owner, skillWalletOwner);
        assert.equal(skillWalletActivated, false)

      })
      it('should transfer the token to the owner if not claimable', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          false,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const skillWalletClaimable = await this.skillWallet.isSkillWalletClaimable(
          skillWalletOwner,
        )

        assert.equal(skillWalletClaimable, false)

        const owner = await this.skillWallet.ownerOf(
          tokenId
        );

        const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner
        )
        const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )

        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(owner, skillWalletOwner);
        assert.equal(skillWalletActivated, false)

      })
      it('should fail claiming not claimable SW', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          false,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const skillWalletClaimable = await this.skillWallet.isSkillWalletClaimable(
          skillWalletOwner,
        )

        assert.equal(skillWalletClaimable, false)

        const claimedTx = this.skillWallet.claim({ from: skillWalletOwner });

        await truffleAssert.reverts(
          claimedTx,
          'SkillWallet: There is SkillWallet already registered for this address.',
        )

      })
    })

    describe('Adding a pubKey to a SkillWallet', async function () {
      it('should fail when the SW is not created yet', async function () {
        const failingTx = this.skillWallet.addPubKeyToSkillWallet(1000000, '', {
          from: creator,
        })
        await truffleAssert.reverts(
          failingTx,
          'SkillWallet: skillWalletId out of range.',
        )
      })
      it('should fail when the call is not made by the owner', async function () {
        const failingTx = this.skillWallet.addPubKeyToSkillWallet(1000000, '')
        await truffleAssert.reverts(
          failingTx,
          'Ownable: caller is not the owner',
        )
      })

      it('should fail when the SW has not been claimed yet.', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const failingTx = this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        await truffleAssert.reverts(
          failingTx,
          "SkillWallet: Skill wallet hasn't been claimed yet.",
        )
      })

      it('should fail when the SW has pubKey already assigned.', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const claimedTx = await this.skillWallet.claim({ from: skillWalletOwner });
        const claimedTxEvent = claimedTx.logs[2].event === 'SkillWalletClaimed'

        assert.equal(claimedTxEvent, true);

        const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        const pubKeyEventEmitted =
          pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
        assert.equal(pubKeyEventEmitted, true)

        const failingTx = this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        await truffleAssert.reverts(
          failingTx,
          'SkillWallet: Skill wallet already has pubKey assigned.',
        )
      })

      it('should set pubKey properly', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          true,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const claimedTx = await this.skillWallet.claim({ from: skillWalletOwner });
        const claimedTxEvent = claimedTx.logs[2].event === 'SkillWalletClaimed'

        assert.equal(claimedTxEvent, true);

        const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        const pubKeyEventEmitted =
          pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
        assert.equal(pubKeyEventEmitted, true)

        const skillWalletRegistered = await this.skillWallet.isSkillWalletRegistered(
          skillWalletOwner,
        )
        const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner,
        )
        const skillWalletActiveCommunity = await this.skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await this.skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )

        const pubKey = await this.skillWallet.skillWalletToPubKey(tokenId)
        assert.equal(skillWalletRegistered, true)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, community)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], community)
        assert.equal(pubKey, 'pubKey')
      })

      it('should set pubKey properly', async function () {
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          false,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.equal(SWCreated, true)

        const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        const pubKeyEventEmitted =
          pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
        assert.equal(pubKeyEventEmitted, true)

        const skillWalletRegistered = await this.skillWallet.isSkillWalletRegistered(
          skillWalletOwner,
        )
        const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(
          skillWalletOwner,
        )
        const skillWalletActiveCommunity = await this.skillWallet.getActiveCommunity(
          tokenId,
        )
        const skillWalletCommunityHistory = await this.skillWallet.getCommunityHistory(
          tokenId,
        )
        const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )

        const pubKey = await this.skillWallet.skillWalletToPubKey(tokenId)
        assert.equal(skillWalletRegistered, true)
        assert.equal(skillWalletId.toString(), tokenId.toString())
        assert.equal(skillWalletActiveCommunity, community)
        assert.equal(skillWalletActivated, false)
        assert.equal(skillWalletCommunityHistory[0], community)
        assert.equal(pubKey, 'pubKey')
      })
    })

    describe('Activate skillWallet', async function () {
      it('should activate the SW if the response of the chainlink callback is true', async function () {
        // Create SkillWallet
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.isTrue(SWCreated)

        const claimedTx = await this.skillWallet.claim({ from: skillWalletOwner });
        const claimedTxEvent = claimedTx.logs[2].event === 'SkillWalletClaimed'

        assert.equal(claimedTxEvent, true);

        // Add pubKey to the created SkillWallet
        const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        const pubKeyEventEmitted =
          pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
        assert.isTrue(pubKeyEventEmitted)

        const signature = ''

        await this.linkTokenMock.transfer(
          this.skillWallet.address,
          '2000000000000000000',
        )
        const validationTx = await this.skillWallet.validate(
          signature,
          tokenId,
          0,
          [],
          [],
          [],
        )
        const validationRequestIdSentEventEmitted =
          validationTx.logs[1].event === 'ValidationRequestIdSent'

        assert.isTrue(validationRequestIdSentEventEmitted)
        const requestId = validationTx.logs[0].args[0]

        const fulfilTx = await this.mockOracle.methods["fulfillOracleRequest(bytes32,bool)"](
          requestId,
          true,
        )
        const fulfilTxEventEmitted = fulfilTx.logs[0].event === 'CallbackCalled'

        assert.isTrue(fulfilTxEventEmitted)
        const isSWActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )
        assert.isTrue(isSWActivated)
      })
      it('should not activate the SW if the response of the chainlink callback is false', async function () {
        // Create SkillWallet
        const tx = await this.skillWallet.create(
          skillWalletOwner,
          metadataUrl,
          { from: community },
        )
        const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
        const tokenId = tx.logs[1].args[2]

        assert.isTrue(SWCreated)

        const claimedTx = await this.skillWallet.claim({ from: skillWalletOwner });
        const claimedTxEvent = claimedTx.logs[2].event === 'SkillWalletClaimed'
        assert.isTrue(claimedTxEvent);

        // Add pubKey to the created SkillWallet
        const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
          tokenId,
          'pubKey',
          { from: creator },
        )

        const pubKeyEventEmitted =
          pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
        assert.isTrue(pubKeyEventEmitted)

        const signature = '';

        await this.linkTokenMock.transfer(
          this.skillWallet.address,
          '2000000000000000000',
        )
        const validationTx = await this.skillWallet.validate(
          signature,
          tokenId,
          0,
          [],
          [],
          [],
        )
        const validationRequestIdSentEventEmitted =
          validationTx.logs[1].event === 'ValidationRequestIdSent'

        assert.isTrue(validationRequestIdSentEventEmitted)
        const requestId = validationTx.logs[0].args[0]

        const fulfilTx = await this.mockOracle.methods["fulfillOracleRequest(bytes32,bool)"](
          requestId,
          false
        )
        const fulfilTxEventEmitted = fulfilTx.logs[0].event === 'CallbackCalled'

        assert.isTrue(fulfilTxEventEmitted)
        const isSWActivated = await this.skillWallet.isSkillWalletActivated(
          tokenId,
        )
        assert.isFalse(isSWActivated)
      })
    })
  })
})
