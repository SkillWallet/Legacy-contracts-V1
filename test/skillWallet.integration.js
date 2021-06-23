const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');

const Community = artifacts.require('Community');
const SkillWallet = artifacts.require('SkillWallet');
const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";
var BN = web3.utils.BN;
let skillSet = [[1, 1], [1, 1], [1, 1]];

contract('SkillWallet', function ([_, registryFunder, community, creator, skillWalletOwner, skillWalletOwner2, skillWalletOwner3, notASkillWalletOwner]) {

    before(async function () {
    })
    beforeEach(async function () {
        this.skillWallet = await SkillWallet.new({ from: creator });
        this.community = await Community.new(this.skillWallet.address);
    });

    describe.only('SkillWallet', async function () {
        describe('Creating a SkillWallet', async function () {
            it("should fail when there is already a SW created for this user", async function () {

                const tx = await this.skillWallet.create(
                    skillWalletOwner,
                    skillSet,
                    metadataUrl,
                );

                const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
                assert.equal(SWCreated, true);

                const failingTx = this.skillWallet.create(
                    skillWalletOwner,
                    skillSet,
                    metadataUrl
                );
                await truffleAssert.reverts(
                    failingTx,
                    "SkillWallet: There is SkillWallet already registered for this address."
                );
            });
            it("should create an inactive SW", async function () {

                const tx = await this.skillWallet.create(
                    skillWalletOwner,
                    skillSet,
                    metadataUrl,
                    { from: community }
                );
                const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
                const tokenId = tx.logs[1].args[2];

                assert.equal(SWCreated, true);


                const skillWalletRegistered = await this.skillWallet.isSkillWalletRegistered(skillWalletOwner);
                const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(skillWalletOwner);
                const skillWalletActiveCommunity = await this.skillWallet.getActiveCommunity(tokenId);
                const skillWalletCommunityHistory = await this.skillWallet.getCommunityHistory(tokenId);
                const skillWalletSkillSet = await this.skillWallet.getSkillSet(tokenId);
                const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(tokenId);

                assert.equal(skillWalletRegistered, true);
                assert.equal(skillWalletId.toString(), tokenId.toString());
                assert.equal(skillWalletActiveCommunity, community);
                assert.equal(skillWalletActivated, false);
                assert.equal(skillWalletSkillSet['skill2']['displayStringId'].toString(), '1');
                assert.equal(skillWalletSkillSet['skill2']['level'].toString(), '1');
                assert.equal(skillWalletCommunityHistory[0], community);
            });
        });

        describe('Adding a pubKey to a SkillWallet', async function () {
            it("should fail when the SW is not created yet", async function () {
                const failingTx = this.skillWallet.addPubKeyToSkillWallet(
                    1000000,
                    "",
                    { from: creator }
                );
                await truffleAssert.reverts(
                    failingTx,
                    "SkillWallet: skillWalletId out of range."
                );
            });
            it("should fail when the call is not made by the owner", async function () {
                const failingTx = this.skillWallet.addPubKeyToSkillWallet(
                    1000000,
                    ""
                );
                await truffleAssert.reverts(
                    failingTx,
                    "Ownable: caller is not the owner"
                );
            });

            it("should fail when the SW has pubKey already assigned.", async function () {

                const tx = await this.skillWallet.create(
                    skillWalletOwner,
                    skillSet,
                    metadataUrl,
                    { from: community }
                );
                const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
                const tokenId = tx.logs[1].args[2];

                assert.equal(SWCreated, true);

                const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
                    tokenId,
                    "pubKey",
                    { from: creator }
                );

                const pubKeyEventEmitted = pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
                assert.equal(pubKeyEventEmitted, true);

                const failingTx = this.skillWallet.addPubKeyToSkillWallet(
                    tokenId,
                    "pubKey",
                    { from: creator }
                );

                await truffleAssert.reverts(
                    failingTx,
                    "SkillWallet: Skill wallet already has pubKey assigned."
                );
            });
            it("should set pubKey properly", async function () {

                const tx = await this.skillWallet.create(
                    skillWalletOwner,
                    skillSet,
                    metadataUrl,
                    { from: community }
                );
                const SWCreated = tx.logs[1].event === 'SkillWalletCreated'
                const tokenId = tx.logs[1].args[2];

                assert.equal(SWCreated, true);

                const pubKeyTx = await this.skillWallet.addPubKeyToSkillWallet(
                    tokenId,
                    "pubKey",
                    { from: creator }
                );

                const pubKeyEventEmitted = pubKeyTx.logs[0].event === 'PubKeyAddedToSkillWallet'
                assert.equal(pubKeyEventEmitted, true);

                const skillWalletRegistered = await this.skillWallet.isSkillWalletRegistered(skillWalletOwner);
                const skillWalletId = await this.skillWallet.getSkillWalletIdByOwner(skillWalletOwner);
                const skillWalletActiveCommunity = await this.skillWallet.getActiveCommunity(tokenId);
                const skillWalletCommunityHistory = await this.skillWallet.getCommunityHistory(tokenId);
                const skillWalletSkillSet = await this.skillWallet.getSkillSet(tokenId);
                const skillWalletActivated = await this.skillWallet.isSkillWalletActivated(tokenId);

                const pubKey = await this.skillWallet.skillWalletToPubKey(tokenId);
                assert.equal(skillWalletRegistered, true);
                assert.equal(skillWalletId.toString(), tokenId.toString());
                assert.equal(skillWalletActiveCommunity, community);
                assert.equal(skillWalletActivated, false);
                assert.equal(skillWalletSkillSet['skill2']['displayStringId'].toString(), '1');
                assert.equal(skillWalletSkillSet['skill2']['level'].toString(), '1');
                assert.equal(skillWalletCommunityHistory[0], community);
                assert.equal(pubKey, 'pubKey');
            });
        });
    });
});