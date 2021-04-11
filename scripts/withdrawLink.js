/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");

const main = async () => {
    const skillWalletContractAddress = config.skillWalletAddress[config.defaultNetwork];
    const communityRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];


    const communityRegistryFactory = await ethers.getContractFactory("CommunitiesRegistry");
    const communityRegistryInstance = await communityRegistryFactory.attach(communityRegistryAddress);

    const skillWalletFactory = await ethers.getContractFactory("SkillWallet");
    const skillWalletInstance = await skillWalletFactory.attach(skillWalletContractAddress);

    await communityRegistryInstance.withdrawLink();
    await skillWalletInstance.withdrawLink();


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
