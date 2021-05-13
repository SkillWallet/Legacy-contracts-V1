/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");


const main = async () => {
    const skillWalletAddress = config.skillWalletAddress[config.defaultNetwork];


    //
    const skillWalletFactory = await ethers.getContractFactory("SkillWallet");
    const skillWalletInstance = await skillWalletFactory.attach(skillWalletAddress);

    await skillWalletInstance.cancelRequest();
};


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
