const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");


use(solidity);

describe("SkillWallet tests tests", function () {

    const amount = (n) => {
        return ethers.utils.parseEther(n)
    }

    let communityRegistryInstance;
    let skillWalletInstance;
    let gigsInstance;
    let communityInstance;
    let provider;
    let accounts;
    let account0;
    let account1;
    const skillWalletContractName = "SkillWallet";
    const skillWalletContractSymbol = "SW";

    before(async function () {
        accounts = await ethers.getSigners();
        account0 = accounts[0];
        account1 = accounts[1];

        // Deploy instances
        const CommunityRegistryFactory = await ethers.getContractFactory("CommunitiesRegistry");

        const SkillWalletFactory = await ethers.getContractFactory("SkillWallet");
        const GigsFactory = await ethers.getContractFactory("Gigs");
        const CommunityFactory = await ethers.getContractFactory("Community");

        skillWalletInstance = await SkillWalletFactory.deploy();
        await skillWalletInstance.deployed();

        provider = skillWalletInstance.provider;

        let blockNumber = await provider.getBlockNumber();
        console.log("Current block number", blockNumber);

        communityRegistryInstance = await CommunityRegistryFactory.deploy(skillWalletInstance.address);
        await communityRegistryInstance.deployed();

        gigsInstance = await GigsFactory.deploy();
        await gigsInstance.deployed();

        // Create genesis community
        const community = await communityRegistryInstance.createCommunity(
            "https://hub.textile.io/thread/bafkwfcy3l745x57c7vy3z2ss6ndokatjllz5iftciq4kpr4ez2pqg3i/buckets/bafzbeiaorr5jomvdpeqnqwfbmn72kdu7vgigxvseenjgwshoij22vopice",
            0,
            0,
            'GenesisTown',
            3,
            6,
            12,
            24
        );

        const txReceipt = await community.wait();

        const communityCreatedEvent = txReceipt.events.find(txReceiptEvent =>  txReceiptEvent.event === 'CommunityCreated');
        const communityAddress = communityCreatedEvent.args[1];

        communityInstance = await CommunityFactory.attach(communityAddress);

    })


    describe("SkillWallet", function() {

        it("should be deployed correctly", async function () {
            const name = await skillWalletInstance.name();
            const symbol = await skillWalletInstance.symbol();
            const totalWalletsRegistered = await skillWalletInstance.getTotalSkillWalletsRegistered();

            expect (name).to.be.equal(skillWalletContractName);
            expect (symbol).to.be.equal(skillWalletContractSymbol);
            expect (totalWalletsRegistered).to.be.equal(ethers.BigNumber.from(0));
        });

        it("should work properly", async function () {

            // join community as new member
            let userAddress = ethers.utils.getAddress(account0.address);
            let credits = ethers.utils.parseEther("2006");
            let oneBn = ethers.BigNumber.from(1);
            let communityAddress = communityInstance.address
            await communityRegistryInstance.joinNewMember(communityAddress, userAddress, oneBn, oneBn, oneBn, oneBn, oneBn, oneBn, '', credits)

            const skillWalletRegistered = await skillWalletInstance.isSkillWalletRegistered(userAddress);
            const skillWalletId = await skillWalletInstance.getSkillWalletIdByOwner(userAddress);
            const skillWalletActiveCommunity = await skillWalletInstance.getActiveCommunity(0);
            const skillWalletCommunityHistory = await skillWalletInstance.getCommunityHistory(0);
            const skillWalletSkillSet = await skillWalletInstance.getSkillSet(0);
            const skillWalletActivated = await skillWalletInstance.isSkillWalletActivated(0);

            expect (skillWalletRegistered).to.be.equal(true);
            expect (skillWalletId).to.be.equal(ethers.BigNumber.from(0));
            expect (skillWalletActiveCommunity).to.be.equal(communityAddress);
            expect (skillWalletActivated).to.be.equal(false);
            expect (skillWalletSkillSet['skill1']['displayStringId']).to.be.equal(oneBn);
            expect (skillWalletSkillSet['skill1']['level']).to.be.equal(oneBn);
            expect (skillWalletCommunityHistory[0]).to.be.equal(communityAddress);






        });


    })




});