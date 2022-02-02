/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers, upgrades } = require("hardhat");


const main = async () => {

    console.log("\n\n 📡 Deploying...\n");

    const skillWalletAddress = '0x870FFb101Ba8Ce83df0Ddd1d30Aeb0539D4B2CB3'
    const CommunityRegistry = await ethers.getContractFactory('CommunityRegistry');

    const communityRegistry = await upgrades.deployProxy(CommunityRegistry, [
        skillWalletAddress
    ], {
        initializer: 'initialize',
        unsafeAllowLinkedLibraries: true
    });

    await communityRegistry.deployed();

    console.log('CommunityRegistry deployed to:', communityRegistry.address);
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
