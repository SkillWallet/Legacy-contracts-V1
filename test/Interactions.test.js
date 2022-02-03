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
const SkillWallet = artifacts.require('skill-wallet/contracts/main/SkillWalletID');
const InteractionFactory = artifacts.require('InteractionNFTFactory');
const ActivitiesFactory = artifacts.require('ActivitiesFactory');

contract('Interactions', function (accounts) {
    before(async function () {
        // this.erc1820 = await singletons.ERC1820Registry(accounts[1]);

        this.linkTokenMock = await LinkToken.new()
        this.mockOracle = await MockOracle.new(this.linkTokenMock.address)
        this.skillWallet = await SkillWallet.new(this.linkTokenMock.address, this.mockOracle.address);
        this.activitiesFactory = await ActivitiesFactory.new();

        this.minimumCommunity = await MinimumCommunity.new(
            accounts[0],
            "url",
            2,
            100,
            10,
            1,
            this.skillWallet.address,
            false,
            ZERO_ADDRESS);

        this.interactionFactory = await InteractionFactory.new();

        this.partnersAgreement = await PartnersAgreement.new(
            this.skillWallet.address,
            this.interactionFactory.address,
            {
                version: 1,
                owner: accounts[0],
                communityAddress: this.minimumCommunity.address,
                partnersContracts: [ZERO_ADDRESS],
                rolesCount: 3,
                interactionContract: ZERO_ADDRESS,
                commitmentLevel: 100,
            }
        );


        const community = await MinimumCommunity.at(await this.partnersAgreement.communityAddress());
        await community.joinNewMember('', 1, { from: accounts[0] });
    });
    describe('Interaction tests', async function () {

        it("PartnersAgreement should deploy and mint correct amount of InteractionNFTs when the roles are 3", async function () {
            const partnersAgreement = await PartnersAgreement.new(
                this.skillWallet.address,
                this.interactionFactory.address,
                {
                    version: 1,
                    owner: accounts[0],
                    communityAddress: this.minimumCommunity.address,
                    partnersContracts: [],
                    rolesCount: 3,
                    interactionContract: ZERO_ADDRESS,
                    commitmentLevel: 100,
                }
            );

            await partnersAgreement.deployActivities(this.activitiesFactory.address);

            const activitiesAddress = await partnersAgreement.activities();
            expect(activitiesAddress).not.to.equal(ZERO_ADDRESS);

            const interactionNFTAddress = await partnersAgreement.interactionNFT();
            expect(interactionNFTAddress).not.to.equal(ZERO_ADDRESS);

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
                this.interactionFactory.address,
                {
                    version: 1,
                    owner: accounts[0],
                    communityAddress: this.minimumCommunity.address,
                    partnersContracts: [],
                    rolesCount: 2,
                    interactionContract: ZERO_ADDRESS,
                    commitmentLevel: 100,
                }
            );

            const community = await MinimumCommunity.at(await partnersAgreement.communityAddress());
            await community.joinNewMember('', 1, { from: accounts[1] });
            
            await partnersAgreement.deployActivities(this.activitiesFactory.address);

            const activitiesAddress = await partnersAgreement.activities();
            expect(activitiesAddress).not.to.equal(ZERO_ADDRESS);

            const interactionNFTAddress = await partnersAgreement.interactionNFT();
            expect(interactionNFTAddress).not.to.equal(ZERO_ADDRESS);

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
