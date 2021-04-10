/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    const skillWalletAddress = "0xe13AC8cEb84B1942f060becA7407DDb144F4Da92";

    //
    const skillWalletContractFactory = await ethers.getContractFactory("SkillWallet");
    const skillWalletContractInstance = await skillWalletContractFactory.attach(skillWalletAddress);

    const randomNumber = await skillWalletContractInstance.getRandomNumber(0);

    console.log("Random number", randomNumber.toString())

    // Activate skill wallet
    // const activateSkillWallet = await skillWalletContractInstance.activateSkillWallet(ethers.BigNumber.from(0), randomNumber);


    const isSkillWalletActivated = await skillWalletContractInstance.isSkillWalletActivated(0);

    console.log("SkillWallet ACTIVATED", isSkillWalletActivated)



};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
