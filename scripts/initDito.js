/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");


const createSkillWallet = async (communityRegistryInstance, communityInstance) => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();

    let oneBn = ethers.BigNumber.from(1);
    let communityAddress = communityInstance.address
    await communityRegistryInstance.joinNewMember(communityAddress, deployerWalletAddress, oneBn, oneBn, oneBn, oneBn, oneBn, oneBn, '')

}

const main = async () => {
    const communitiesRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];

    console.log("\n\n 📡 Deploying...\n");

    //
    const communityRegistryFactory = await ethers.getContractFactory("CommunitiesRegistry");
    const communityFactory = await ethers.getContractFactory("Community");
    const communityRegistryInstance = await communityRegistryFactory.attach(communitiesRegistryAddress);



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

    const communityInstance = await communityFactory.attach(communityAddress);

    await createSkillWallet(communityRegistryInstance, communityInstance)

    console.log(
        " 💾  Artifacts (address, abi, and args) saved to: ",
        chalk.blue("packages/hardhat/artifacts/"),
        "\n\n"
    );
};


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
