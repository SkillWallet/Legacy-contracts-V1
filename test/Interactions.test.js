const { singletons, constants } = require('@openzeppelin/test-helpers');
const { assert } = require('chai');
const { artifacts } = require('hardhat');
const { ZERO_ADDRESS } = constants;
const truffleAssert = require('truffle-assertions');

const MinimumCommunity = artifacts.require('Community');
const LinkToken = artifacts.require('LinkToken');
const MockOracle = artifacts.require('MockOracle');
const PartnersAgreement = artifacts.require('PartnersAgreement');
const InteractionNFT = artifacts.require('InteractionNFT');
const Membership = artifacts.require('Membership');
const MembershipFactory = artifacts.require('MembershipFactory');
const SkillWallet = artifacts.require('skill-wallet/contracts/main/SkillWallet');
const InteractionFactory = artifacts.require('InteractionNFTFactory');
const metadataUrl = "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice";
var BN = web3.utils.BN;

contract('Interactions', function (accounts) {
    before(async function () {
        this.erc1820 = await singletons.ERC1820Registry(accounts[1]);

        this.linkTokenMock = await LinkToken.new()
        this.mockOracle = await MockOracle.new(this.linkTokenMock.address)

        this.skillWallet = await SkillWallet.new(this.linkTokenMock.address, this.mockOracle.address);


        this.minimumCommunity = await MinimumCommunity.new(
            metadataUrl,
            1,
            100,
            accounts[1],
            ZERO_ADDRESS,
            1,
            this.skillWallet.address,
            false);
        //this.roleUtils = await RoleUtils.new();

        //PartnersAgreement.link(this.roleUtils);
        this.interactionFactory = await InteractionFactory.new();
        this.membershipFactory = await MembershipFactory.new(1);

        this.partnersAgreement = await PartnersAgreement.new(
            this.skillWallet.address,
            this.membershipFactory.address,
            this.interactionFactory.address,
            {
                version: 1,
                owner: accounts[0],
                communityAddress: this.minimumCommunity.address,
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

        this.membership = await Membership.at(await this.partnersAgreement.membershipAddress());

        const community = await MinimumCommunity.at(await this.partnersAgreement.communityAddress());
        await community.joinNewMember('', 1, { from: accounts[0] });
        await this.partnersAgreement.activatePA({ from: accounts[0] });

        await this.linkTokenMock.transfer(
            this.partnersAgreement.address,
            '2000000000000000000',
        )

    });
    describe('Interaction tests', async function () {

        it("PartnersAgreement should deploy and mint correct amount of InteractionNFTs when the roles are 3", async function () {
            const partnersAgreement = await PartnersAgreement.new(
                this.skillWallet.address,
                this.membershipFactory.address,
                this.interactionFactory.address,
                {
                    version: 1,
                    owner: accounts[0],
                    communityAddress: this.minimumCommunity.address,
                    partnersContracts: [],
                    rolesCount: 3,
                    interactionContract: ZERO_ADDRESS,
                    membershipContract: ZERO_ADDRESS,
                    interactionsCount: 100,
                    coreTeamMembersCount: 3,
                    whitelistedTeamMembers: [],
                    interactionsQueryServer: accounts[3]
                }
            );

            const community = await MinimumCommunity.at(await partnersAgreement.communityAddress());
            await partnersAgreement.activatePA();

            const interactionNFTAddress = await partnersAgreement.getInteractionNFTContractAddress();
            const interactionNFTContract = await InteractionNFT.at(interactionNFTAddress);

            const balanceRole0 = await interactionNFTContract.balanceOf(partnersAgreement.address, 1);
            const balanceRole1 = await interactionNFTContract.balanceOf(partnersAgreement.address, 2);
            const balanceRole2 = await interactionNFTContract.balanceOf(partnersAgreement.address, 3);


            const totalSupply0 = await interactionNFTContract.totalSupply(1);
            const totalSupply1 = await interactionNFTContract.totalSupply(2);
            const totalSupply2 = await interactionNFTContract.totalSupply(3);

            assert.equal(balanceRole0.toString(), totalSupply0.toString());
            assert.equal(balanceRole1.toString(), totalSupply1.toString());
            assert.equal(balanceRole2.toString(), totalSupply2.toString());

            assert.equal(balanceRole2.toString(), '14');
            assert.equal(balanceRole1.toString(), '29');
            assert.equal(balanceRole0.toString(), '57');

        });
        it("PartnersAgreement should deploy and mint correct amount of InteractionNFTs when the roles are 2", async function () {
            const partnersAgreement = await PartnersAgreement.new(
                this.skillWallet.address,
                this.membershipFactory.address,
                this.interactionFactory.address,
                {
                    version: 1,
                    owner: accounts[0],
                    communityAddress: this.minimumCommunity.address,
                    partnersContracts: [],
                    rolesCount: 2,
                    interactionContract: ZERO_ADDRESS,
                    membershipContract: ZERO_ADDRESS,
                    interactionsCount: 100,
                    coreTeamMembersCount: 3,
                    whitelistedTeamMembers: [],
                    interactionsQueryServer: accounts[3]
                },
                { from: accounts[0] }
            );

            const community = await MinimumCommunity.at(await partnersAgreement.communityAddress());
            await community.joinNewMember('', 1, { from: accounts[1] });
            await partnersAgreement.activatePA({ from: accounts[1] });

            const interactionNFTAddress = await partnersAgreement.getInteractionNFTContractAddress();
            const interactionNFTContract = await InteractionNFT.at(interactionNFTAddress);

            const balanceRole0 = await interactionNFTContract.balanceOf(partnersAgreement.address, 1);
            const balanceRole1 = await interactionNFTContract.balanceOf(partnersAgreement.address, 2);

            const totalSupply0 = await interactionNFTContract.totalSupply(1);
            const totalSupply1 = await interactionNFTContract.totalSupply(2);

            assert.equal(balanceRole0.toString(), totalSupply0.toString());
            assert.equal(balanceRole1.toString(), totalSupply1.toString());

            assert.equal(balanceRole1.toString(), '43');
            assert.equal(balanceRole0.toString(), '57');

        });
        it.skip('transferInteractionNFTs should transfer the correct amount of NFTs', async function () {
            const initialInteractions = await this.partnersAgreement.getInteractionNFT(accounts[0]);

            assert.equal(initialInteractions.toString(), '0');

            let tx = await this.partnersAgreement.transferInteractionNFTs(
                accounts[0],
                10,
                { from: accounts[3] }
            )

            const interactions = await this.partnersAgreement.getInteractionNFT(accounts[0]);

            assert.equal(interactions.toString(), '10');
        })

        it.skip('transferInteractionNFTs should not transfer the NFTs if the sender or arguemtns are wrong', async function () {
            const initialInteractions = await this.partnersAgreement.getInteractionNFT(accounts[0]);

            await truffleAssert.reverts(
                this.partnersAgreement.transferInteractionNFTs(
                    accounts[0],
                    10,
                    { from: accounts[2] }
                ),
                'Only activities!',
            );

            await truffleAssert.reverts(
                this.partnersAgreement.transferInteractionNFTs(
                    ZERO_ADDRESS,
                    10,
                    { from: accounts[3] }
                ),
                'Invalid user address',
            );

            await truffleAssert.reverts(
                this.partnersAgreement.transferInteractionNFTs(
                    accounts[10],
                    10,
                    { from: accounts[3] }
                ),
                'Invalid user address',
            );

            await truffleAssert.reverts(
                this.partnersAgreement.transferInteractionNFTs(
                    accounts[10],
                    0,
                    { from: accounts[3] }
                ),
                'Invalid amount of interactions',
            );
            const interactions = await this.partnersAgreement.getInteractionNFT(accounts[0]);

            assert.equal(interactions.toString(), initialInteractions.toString());
        })
    });
});
