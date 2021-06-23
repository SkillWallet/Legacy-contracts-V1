// const { expectEvent, singletons, constants } = require('@openzeppelin/test-helpers');
// const { assert } = require('chai');
// const { ZERO_ADDRESS } = constants;
// const truffleAssert = require('truffle-assertions');

// const DistributedTown = artifacts.require('DistributedTown');
// const Community = artifacts.require('Community');
// const SkillWallet = artifacts.require('SkillWallet');
// const Gigs = artifacts.require('Gigs');
// const AddressProvider = artifacts.require('AddressProvider');
// const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";
// var BN = web3.utils.BN;


// contract('Gigs', function ([_, registryFunder, creator, firstMember, secondMember, thirdMember, notAMember]) {

//     before(async function () {
//         this.erc1820 = await singletons.ERC1820Registry(registryFunder);
//         this.gigStatuses = await GigStatuses.new();
//         AddressProvider.link(this.gigStatuses);
//     })
//     beforeEach(async function () {
//         this.addressProvder = await AddressProvider.new();
//         this.skillWallet = await SkillWallet.new({ from: creator });
//         this.distirbutedTown = await DistributedTown.new('http://someurl.co', this.skillWallet.address, this.addressProvder.address, { from: creator });
//         await this.distirbutedTown.deployGenesisCommunities(0, { from: creator });
//         const communities = await this.distirbutedTown.getCommunities();
//         this.community = await Community.at(communities[0]);
//         this.ditoCreditCommunityHolder = await this.community.ditoCreditsHolder();
//         const gigsAddr = await this.community.gigsAddr();
//         this.gigs = await Gigs.at(gigsAddr);
//         await this.community.joinNewMember(1, 1, 2, 2, 3, 3, 'http://someuri.co', web3.utils.toWei(new BN(2006)), { from: firstMember });
//         await this.community.joinNewMember(1, 1, 2, 2, 3, 3, 'http://someuri.co', web3.utils.toWei(new BN(2006)), { from: secondMember });
//         await this.community.joinNewMember(1, 1, 2, 2, 3, 3, 'http://someuri.co', web3.utils.toWei(new BN(2006)), { from: thirdMember });
//     });

//     describe('Gigs flow', async function () {

//         describe('Creating a gig', async function () {

//             it("should fail when the gig creator isn't a community member", async function () {

//                 const tx = this.gigs.createGig(
//                     '0x093ECac1110EF08976A0A1F24393c3e48936489D',
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 await truffleAssert.reverts(
//                     tx,
//                     "The creator of the gig should be a member of the community."
//                 );
//             });
//             it("should fail when the dito credits are invalid amount", async function () {

//                 const tx = this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(2)),
//                     metadataUrl
//                 );

//                 const tx1 = this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(1000)),
//                     metadataUrl
//                 );
//                 await truffleAssert.reverts(
//                     tx,
//                     "Invalid credits amount."
//                 );
//                 await truffleAssert.reverts(
//                     tx1,
//                     "Invalid credits amount."
//                 );
//             });
//             it("should fail when the creator doesn't have enough credits", async function () {
//                 const creditsHolderBalanceBefore = await this.community.balanceOf(this.ditoCreditCommunityHolder);
//                 const tx1 = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(720)),
//                     metadataUrl
//                 );
//                 const gigCreatedEvent1 = tx1.logs[1].event === 'GigCreated'
//                 assert.equal(gigCreatedEvent1, true);

//                 const tx2 = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(720)),
//                     metadataUrl
//                 );

//                 const gigCreatedEvent2 = tx2.logs[1].event === 'GigCreated'
//                 assert.equal(gigCreatedEvent2, true);

//                 const creatorBalance = await this.community.balanceOf(firstMember);
//                 assert.equal(creatorBalance.toString(), web3.utils.toWei(new BN(566)).toString());
//                 const creditsHolderBalanceAfter = await this.community.balanceOf(this.ditoCreditCommunityHolder);

//                 assert.equal((+web3.utils.fromWei(creditsHolderBalanceBefore.toString()) + 1440), +web3.utils.fromWei(creditsHolderBalanceAfter.toString()));

//                 const tx = this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(600)),
//                     metadataUrl
//                 );

//                 await truffleAssert.reverts(
//                     tx,
//                     "Insufficient dito balance"
//                 );
//             });
//             it('should create a gig and transfer the credits correctly', async function () {
//                 const balanceBefore = await this.community.balanceOf(firstMember);
//                 const balanceCreditsHolderBefore = await this.community.balanceOf(this.ditoCreditCommunityHolder);

//                 const creditsAmount = 50;
//                 const tx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(creditsAmount)),
//                     metadataUrl
//                 );
//                 const gigtCreatedEvent = tx.logs[1].event === 'GigCreated'
//                 const creator = tx.logs[1].args[0];
//                 const gigId = tx.logs[1].args[1];
//                 const balanceAfter = await this.community.balanceOf(firstMember);
//                 const balanceCreditsHolderAfter = await this.community.balanceOf(this.ditoCreditCommunityHolder);

//                 assert.equal(gigtCreatedEvent, true);
//                 assert.equal((+web3.utils.fromWei(balanceBefore.toString()) - creditsAmount), +web3.utils.fromWei(balanceAfter.toString()));
//                 assert.equal((+web3.utils.fromWei(balanceCreditsHolderBefore.toString()) + creditsAmount), +web3.utils.fromWei(balanceCreditsHolderAfter.toString()));
//                 assert.equal(creator.toString(), firstMember);

//                 const gig = await this.gigs.gigs(
//                     gigId
//                 );

//                 assert.equal(gig.creator, firstMember);
//                 assert.equal(gig.taker, '0x0000000000000000000000000000000000000000');
//                 assert.equal(gig.status, 0);
//                 assert.equal(gig.ditoCredits.toString(), web3.utils.toWei(new BN(50)).toString());
//                 const isValid = await this.gigs.isValidated(
//                     gigId
//                 );
//                 assert.equal(isValid, false);
//             });
//         });

//         describe('Take a gig', async function () {
//             it("should fail when the gig creator tries to take the gig", async function () {

//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const takeGigTx = this.gigs.takeGig(
//                     gigId,
//                     firstMember
//                 );

//                 await truffleAssert.reverts(
//                     takeGigTx,
//                     "The creator can't take the gig"
//                 );
//             });
//             it("should fail when the gig doesn't exist yet", async function () {

//                 const gigId = 120;
//                 const takeGigTx = this.gigs.takeGig(
//                     gigId,
//                     firstMember
//                 );

//                 await truffleAssert.reverts(
//                     takeGigTx,
//                     "Invalid gigId"
//                 );
//             });
//             it("should fail when the taker is not a part of the community", async function () {

//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const takeGigTx = this.gigs.takeGig(
//                     gigId,
//                     notAMember
//                 );

//                 await truffleAssert.reverts(
//                     takeGigTx,
//                     "The taker should be a community member."
//                 );
//             });
//             it("should fail when the gig hasn't been validated by the creator yet", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const takeGigTx = this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 await truffleAssert.reverts(
//                     takeGigTx,
//                     "The gig should be validated by the creator."
//                 );
//             });
//             it("should fail when the gig is already taken", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);
//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'

//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );
//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const invalidTakeGig = this.gigs.takeGig(
//                     gigId,
//                     thirdMember
//                 );

//                 await truffleAssert.reverts(
//                     invalidTakeGig,
//                     "The gig is already taken."
//                 );
//             });
//             it('should succeed taking a gig and should update the state properly', async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);
//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'

//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );
//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const gig = await this.gigs.gigs(
//                     gigId
//                 );

//                 assert.equal(gig.creator, firstMember);
//                 assert.equal(gig.taker, secondMember);
//                 assert.equal(gig.status, 1);
//                 assert.equal(gig.ditoCredits.toString(), web3.utils.toWei(new BN(200)).toString());
//             });
//         });

//         describe('Submit a gig', async function () {
//             it("should fail when the sender is not the taker", async function () {

//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);


//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);
//                 const submitGigTx = this.gigs.submitGig(
//                     gigId,
//                     thirdMember
//                 );
//                 await truffleAssert.reverts(
//                     submitGigTx,
//                     "Only the taker can submit the gig"
//                 );
//             });
//             it("should fail when the gig doesn't exist yet", async function () {

//                 const gigId = 120;
//                 const takeGigTx = this.gigs.submitGig(
//                     gigId,
//                     firstMember
//                 );

//                 await truffleAssert.reverts(
//                     takeGigTx,
//                     "Invalid gigId"
//                 );
//             });
//             it("should fail when the gig hasn't been validated by the creator yet", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const submitTx = this.gigs.submitGig(
//                     gigId,
//                     secondMember
//                 );

//                 await truffleAssert.reverts(
//                     submitTx,
//                     "The gig should be validated by the creator."
//                 );
//             });
//             it("should fail when the gig isn't taken yet", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);
//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'

//                 assert.equal(markAsValidEvent, true);

//                 const invalidSubmitGig = this.gigs.submitGig(
//                     gigId,
//                     thirdMember
//                 );

//                 await truffleAssert.reverts(
//                     invalidSubmitGig,
//                     "Gig not taken yet."
//                 );
//             });
//             it('should succeed submitting a gig and should update the state properly', async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);


//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);

//                 const submitTx = await this.gigs.submitGig(
//                     gigId,
//                     secondMember
//                 );

//                 const subnittedGigEvent = submitTx.logs[0].event === 'GigSubmitted'
//                 assert.equal(subnittedGigEvent, true);

//                 const gig = await this.gigs.gigs(
//                     gigId
//                 );

//                 assert.equal(gig.creator, firstMember);
//                 assert.equal(gig.taker, secondMember);
//                 assert.equal(gig.status, 2);
//                 assert.equal(gig.ditoCredits.toString(), web3.utils.toWei(new BN(200)).toString());



//             });
//         });

//         describe('Complete a gig', async function () {
//             it("should fail when the gig doesn't exist yet", async function () {

//                 const gigId = 120;
//                 const takeGigTx = this.gigs.completeGig(
//                     gigId,
//                     firstMember
//                 );

//                 await truffleAssert.reverts(
//                     takeGigTx,
//                     "Invalid gigId"
//                 );
//             });
//             it("should fail when the completor isn't the creator", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);

//                 const submitTx = await this.gigs.submitGig(
//                     gigId,
//                     secondMember
//                 );

//                 const subnittedGigEvent = submitTx.logs[0].event === 'GigSubmitted'
//                 assert.equal(subnittedGigEvent, true);

//                 const markAsValidSubmittedTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidSubmittedEvent = markAsValidSubmittedTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidSubmittedEvent, true);

//                 const completeTx = this.gigs.completeGig(
//                     gigId,
//                     secondMember
//                 );
               
//                 await truffleAssert.reverts(
//                     completeTx,
//                     "Can be completed only by the creator."
//                 );
//             });
//             it("should fail when the gig submission validation hasn't passed yet", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);

//                 const submitTx = await this.gigs.submitGig(
//                     gigId,
//                     secondMember
//                 );

//                 const subnittedGigEvent = submitTx.logs[0].event === 'GigSubmitted'
//                 assert.equal(subnittedGigEvent, true);


//                 const completeTx = this.gigs.completeGig(
//                     gigId,
//                     firstMember
//                 );
               
//                 await truffleAssert.reverts(
//                     completeTx,
//                     "The gig should be validated by the creator."
//                 );
//             });
//             it("should fail when the gig isn't submitted yet", async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);

//                 const completeTx = this.gigs.completeGig(
//                     gigId,
//                     firstMember
//                 );
               
//                 await truffleAssert.reverts(
//                     completeTx,
//                     "Gig not submitted yet."
//                 );
//             });
//             it('should succeed completing a gig and should update the state properly', async function () {
//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);

//                 const submitTx = await this.gigs.submitGig(
//                     gigId,
//                     secondMember
//                 );

//                 const submittedGigEvent = submitTx.logs[0].event === 'GigSubmitted'
//                 assert.equal(submittedGigEvent, true);

//                 const markAsValidSubmittedTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidSubmittedEvent = markAsValidSubmittedTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidSubmittedEvent, true);

//                 const completeTx = await this.gigs.completeGig(
//                     gigId,
//                     firstMember
//                 );

//                 const completedGigEvent = completeTx.logs[0].event === 'GigCompleted'
//                 assert.equal(completedGigEvent, true);

//                 const gig = await this.gigs.gigs(
//                     gigId
//                 );

//                 assert.equal(gig.creator, firstMember);
//                 assert.equal(gig.taker, secondMember);
//                 assert.equal(gig.status, 3);
//                 assert.equal(gig.ditoCredits.toString(), web3.utils.toWei(new BN(200)).toString());

//             });

//             it('should trasnfer the credits to the taker once validation has passed', async function () {
                
//                 const takerBalanceBeforeTakingGig = await this.community.balanceOf(secondMember);

//                 const createGigTx = await this.gigs.createGig(
//                     firstMember,
//                     web3.utils.toWei(new BN(200)),
//                     metadataUrl
//                 );

//                 const gigtCreatedEvent = createGigTx.logs[1].event === 'GigCreated'
//                 const gigId = createGigTx.logs[1].args[1];

//                 assert.equal(gigtCreatedEvent, true);

//                 const markAsValidTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidEvent = markAsValidTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidEvent, true);

//                 const takeGigTx = await this.gigs.takeGig(
//                     gigId,
//                     secondMember
//                 );

//                 const takeGigEvent = takeGigTx.logs[0].event === 'GigTaken'
//                 assert.equal(takeGigEvent, true);

//                 const markAsValidTakenTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidTakenEvent = markAsValidTakenTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidTakenEvent, true);

//                 const submitTx = await this.gigs.submitGig(
//                     gigId,
//                     secondMember
//                 );

//                 const submittedGigEvent = submitTx.logs[0].event === 'GigSubmitted'
//                 assert.equal(submittedGigEvent, true);

//                 const markAsValidSubmittedTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidSubmittedEvent = markAsValidSubmittedTx.logs[0].event === 'GigValidated'
//                 assert.equal(markAsValidSubmittedEvent, true);

//                 const completeTx = await this.gigs.completeGig(
//                     gigId,
//                     firstMember
//                 );

//                 const completedGigEvent = completeTx.logs[0].event === 'GigCompleted'
//                 assert.equal(completedGigEvent, true);

//                 const takerBalanceBeforeCompleteValidation = await this.community.balanceOf(secondMember);

//                 assert.equal(takerBalanceBeforeCompleteValidation.toString(), takerBalanceBeforeTakingGig.toString());

//                 const ditoHolderBalanceBeforeCompletion = await this.community.balanceOf(this.ditoCreditCommunityHolder);
//                 const gigBeforeCompletion = await this.gigs.gigs(
//                     gigId
//                 );
//                 assert.equal(gigBeforeCompletion.status, 3);

//                 const markAsValidCompletedTx = await this.gigs.markAsValid(
//                     gigId
//                 );
//                 const markAsValidCompletedEvent = markAsValidCompletedTx.logs[0].event === 'GigValidated'
//                 const trasnferredCredits = markAsValidCompletedTx.logs[0].args[1];
//                 const trasnferredCreditsAmount = markAsValidCompletedTx.logs[0].args[2];

//                 assert.equal(markAsValidCompletedEvent, true);
//                 assert.equal(trasnferredCreditsAmount.toString(), web3.utils.toWei(new BN(200)).toString());
//                 assert.equal(trasnferredCredits, true);

//                 const takerBalanceAfterCompleteValidation = await this.community.balanceOf(secondMember);
//                 const ditoHolderBalanceAfterCompletion = await this.community.balanceOf(this.ditoCreditCommunityHolder);

//                 const gig = await this.gigs.gigs(
//                     gigId
//                 );

//                 assert.equal((+web3.utils.fromWei(takerBalanceAfterCompleteValidation.toString())), +web3.utils.fromWei(takerBalanceBeforeCompleteValidation.toString()) + +web3.utils.fromWei(gig.ditoCredits.toString()));
//                 assert.equal((+web3.utils.fromWei(ditoHolderBalanceAfterCompletion.toString())), +web3.utils.fromWei(ditoHolderBalanceBeforeCompletion.toString()) - +web3.utils.fromWei(gig.ditoCredits.toString()));

//                 assert.equal(gig.creator, firstMember);
//                 assert.equal(gig.taker, secondMember);
//                 assert.equal(gig.status, 3);
//                 assert.equal(gig.ditoCredits.toString(), web3.utils.toWei(new BN(200)).toString());

//             });
//         });
//     });
// });