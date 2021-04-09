/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    const skillWalletAddress = "0x14DEF8Be678589dd1445A46Fc5bE925d479694B9";

    console.log("\n\n 📡 Deploying...\n");

    //
    const skillWalletContractFactory = await ethers.getContractFactory("SkillWallet");
    const skillWalletContractInstance = await skillWalletContractFactory.attach(skillWalletAddress);

    const randomString = await skillWalletContractInstance.getRandomString(deployerWalletAddress);

    console.log("Random string obtained", randomString);

};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
