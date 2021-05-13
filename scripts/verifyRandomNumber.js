/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    const skillWalletAddress = config.skillWalletAddress[config.defaultNetwork];

    //
    const skillWalletContractFactory = await ethers.getContractFactory("SkillWallet");
    const skillWalletContractInstance = await skillWalletContractFactory.attach(skillWalletAddress);

    const randomNumber = await skillWalletContractInstance.getRandomNumber(0);

    console.log("Random number", randomNumber.toString())

    // Activate skill wallet
    // const activateSkillWallet = await skillWalletContractInstance.activateSkillWallet(ethers.BigNumber.from(0), randomNumber);


    // const isSkillWalletActivated = await skillWalletContractInstance.isSkillWalletActivated(0);
    //
    // console.log("SkillWallet ACTIVATED", isSkillWalletActivated)



};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
