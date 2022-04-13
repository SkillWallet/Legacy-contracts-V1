const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');
const { upgrades, ethers } = require('hardhat');
const { constants } = require('@openzeppelin/test-helpers');
const { ZERO_ADDRESS } = constants;

let skillWallet;
let community;
let community2;
let permissionedCommunity;
let memberAddress;
let permissionedMember;
let badges;

contract('Community', function (accounts) {
    before(async function () {
        [signer, coreTeamMember1, coreTeamMember2, coreTeamMember2, notACoreTeamMember, ...accounts] = await ethers.getSigners();
        const SkillWallet = await ethers.getContractFactory('SkillWalletID');
        const Community = await ethers.getContractFactory('Community');
        const BadgeNFT = await ethers.getContractFactory('Badges');

        skillWallet = await upgrades.deployProxy(
            SkillWallet,
            ['0x64307b67314b584b1E3Be606255bd683C835A876', '0x64307b67314b584b1E3Be606255bd683C835A876'],
        );

        await skillWallet.deployed();

        memberAddress = accounts[3];
        community = await Community.deploy(
            signer.address,
            "url",
            1,
            100,
            10,
            1,
            skillWallet.address,
            false,
            ZERO_ADDRESS);

        community2 = await Community.deploy(
            signer.address,
            "url",
            2,
            100,
            10,
            1,
            skillWallet.address,
            false,
            ZERO_ADDRESS);
        permissionedMember = accounts[4];

        badges = await BadgeNFT.deploy();
        await badges.deployed();

        permissionedCommunity = await Community.deploy(
            signer.address,
            "url",
            2,
            100,
            10,
            1,
            skillWallet.address,
            true,
            ZERO_ADDRESS);


        await (await community
            .connect(memberAddress)
            .joinNewMember(
                'http://someuri.co',
                1)
        ).wait();

    });
    describe('Join new member (permissionless community)', async function () {

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
            assert.equal(membersCount.toString(), (membersCountBefore + 1).toString());
            assert.equal(isMember, true);
            expect(skillWalletIds[+(membersCount.toString()) - 1].toString()).to.eq(tokenId.toString());
        });
    });
    describe('Join new member (permissioned community)', async function () {
        it("should fail if the user has no Badges NFT address assigned", async function () {
            let tx = permissionedCommunity.connect(permissionedMember).joinNewMember('http://someuri.co', 1);
            await truffleAssert.reverts(
                tx,
                "The user has no permission badge."
            );

            await permissionedCommunity.joinNewMember("", 1);
            await permissionedCommunity.setPermissionBadgeAddress(badges.address);

            let tx2 = permissionedCommunity.connect(permissionedMember).joinNewMember('http://someuri.co', 1);
            await truffleAssert.reverts(
                tx2,
                "The user has no permission badge."
            );
        });

        it("should add new member to the members list if they have badge", async function () {
            const membersCountBefore = await permissionedCommunity.activeMembersCount()

            await badges.mint(permissionedMember.address);

            const tx = await (await permissionedCommunity
                .connect(permissionedMember)
                .joinNewMember(
                    'http://someuri.co',
                    1)
            ).wait();

            const memberAddedEvent = tx.events.find(e => e.event == 'MemberAdded');

            assert.isNotNull(memberAddedEvent)

            const tokenId = memberAddedEvent.args._skillWalletTokenId;
            const membersCount = await permissionedCommunity.activeMembersCount()
            const isMember = await permissionedCommunity.isMember(permissionedMember.address)
            const skillWalletIds = await permissionedCommunity.getMembers();

            const skillWalletRegistered = await skillWallet.isSkillWalletRegistered(permissionedMember.address);
            const skillWalletId = await skillWallet.getSkillWalletIdByOwner(permissionedMember.address);
            const skillWalletActiveCommunity = await skillWallet.getActiveCommunity(tokenId);
            const skillWalletCommunityHistory = await skillWallet.getCommunityHistory(tokenId);
            const skillWalletActivated = await skillWallet.isSkillWalletActivated(tokenId);

            assert.equal(skillWalletRegistered, true);
            assert.equal(skillWalletId.toString(), tokenId.toString());
            assert.equal(skillWalletActiveCommunity, permissionedCommunity.address);
            assert.equal(skillWalletActivated, false);
            assert.equal(skillWalletCommunityHistory[0], permissionedCommunity.address);
            assert.equal(membersCount.toString(), (membersCountBefore + 1).toString());
            assert.equal(isMember, true);
            expect(skillWalletIds[+(membersCount.toString()) - 1].toString()).to.eq(tokenId.toString());
        });
    });
    describe("Core team members", async () => {
        it("Should add owner as core team member after deployment", async () => {
            const isCoreTeamMember = await community.isCoreTeamMember(signer.address);
            const coreTeamMemberWhitelist = await community.getCoreTeamMembers();
            expect(coreTeamMemberWhitelist.length).to.eq(1);
            expect(coreTeamMemberWhitelist[0]).to.eq(signer.address);
            expect(isCoreTeamMember).to.be.true;
        });
        it("Should succeed when the owner adds new core team members to the whitelist", async () => {
            await community.addNewCoreTeamMembers(coreTeamMember1.address);
            const teamMembers = await community.getCoreTeamMembers();
            expect(teamMembers.length).to.eq(2);
            expect(teamMembers[0]).to.eq(signer.address)
            expect(teamMembers[1]).to.eq(coreTeamMember1.address)
        });

        it("Should fail if the core team member hasn't created SW yet", async () => {
            expect(
                community.connect(coreTeamMember1).addNewCoreTeamMembers(coreTeamMember2.address)
            ).to.be.revertedWith("The signer is not whitelisted as core team member!");
        });

        it("Should fail if the core team member hasn't created SW yet", async () => {
            expect(
                community.connect(coreTeamMember1).addNewCoreTeamMembers(coreTeamMember2.address)
            ).to.be.revertedWith("The signer is not whitelisted as core team member!");
        });

        it("Should fail if unlisted core team member attepts to add other core team members", async () => {
            expect(
                community.connect(coreTeamMember2).addNewCoreTeamMembers(coreTeamMember2.address)
            ).to.be.revertedWith("The signer is not whitelisted as core team member!");
        });
        it("Should fail if core team member spots are filled", async () => {
            await community.addNewCoreTeamMembers(coreTeamMember2.address);
            const coreTeamMembers = await community.getCoreTeamMembers();
            expect(
                community.addNewCoreTeamMembers(notACoreTeamMember.address)
            ).to.be.revertedWith("Core team member spots are filled.");
            expect(coreTeamMembers.length).to.eq(3);
            expect(coreTeamMembers[0]).to.eq(signer.address);
            expect(coreTeamMembers[1]).to.eq(coreTeamMember1.address);
            expect(coreTeamMembers[2]).to.eq(coreTeamMember2.address);
        });
    });
});
