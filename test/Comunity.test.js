const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const { upgrades, ethers } = require('hardhat');
const { constants } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

let skillWallet;
let community;
let community2;
let memberAddress;

contract('Community', function (accounts) {

    before(async function () {
        [signer, ...accounts] = await ethers.getSigners();
        const SkillWallet = await ethers.getContractFactory('SkillWallet');
        const Community = await ethers.getContractFactory('Community');

        skillWallet = await upgrades.deployProxy(
            SkillWallet,
            ['0x64307b67314b584b1E3Be606255bd683C835A876', '0x64307b67314b584b1E3Be606255bd683C835A876'],
        );

        await skillWallet.deployed();

        memberAddress = accounts[3];
        community = await Community.deploy(
            "url",
            1,
            100,
            signer.address,
            ZERO_ADDRESS,
            1,
            skillWallet.address,
            false);

        community2 = await Community.deploy(
            "url",
            2,
            100,
            signer.address,
            ZERO_ADDRESS,
            1,
            skillWallet.address,
            false);

        await (await community
            .connect(memberAddress)
            .joinNewMember(
                'http://someuri.co',
                1)
        ).wait();

    });
    describe('Join new member', async function () {

        it("should fail if the user is a member a member of a community", async function () {
            let tx = community2.connect(memberAddress).joinNewMember('http://someuri.co', 1);
            await truffleAssert.reverts(
                tx,
                "SkillWallet: There is SkillWallet already registered for this address."
            );

            tx = community.connect(memberAddress).joinNewMember('http://someuri.co', 1);

            await truffleAssert.reverts(
                tx,
                "Already a member"
            );

        });
        it("should add new member to the members list", async function () {
            const userAccount = accounts[6];
            const userAddress = userAccount.address;
            const membersCountBefore = await community.activeMembersCount()

            const tx = await (await community
                .connect(userAccount)
                .joinNewMember(
                    'http://someuri.co',
                    1)
            ).wait();

            const memberAddedEvent = tx.events.find(e => e.event == 'MemberAdded');

            assert.isNotNull(memberAddedEvent)

            const tokenId = memberAddedEvent.args._skillWalletTokenId;
            const membersCount = await community.activeMembersCount()
            const isMember = await community.isMember(userAddress)
            const skillWalletIds = await community.getMembers();

            const skillWalletRegistered = await skillWallet.isSkillWalletRegistered(userAddress);
            const skillWalletId = await skillWallet.getSkillWalletIdByOwner(userAddress);
            const skillWalletActiveCommunity = await skillWallet.getActiveCommunity(tokenId);
            const skillWalletCommunityHistory = await skillWallet.getCommunityHistory(tokenId);
            const skillWalletActivated = await skillWallet.isSkillWalletActivated(tokenId);

            assert.equal(skillWalletRegistered, true);
            assert.equal(skillWalletId.toString(), tokenId.toString());
            assert.equal(skillWalletActiveCommunity, community.address);
            assert.equal(skillWalletActivated, false);
            assert.equal(skillWalletCommunityHistory[0], community.address);
            assert.equal(membersCount.toString(),(membersCountBefore + 1).toString());
            assert.equal(isMember, true);
            expect(skillWalletIds[+(membersCount.toString()) - 1].toString()).to.eq(tokenId.toString());
        });
    });
});
