/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");


const main = async () => {
    const communitiesRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];

    console.log("\n\n 📡 Deploying...\n");

    //
    const communityRegistryFactory = await ethers.getContractFactory("CommunitiesRegistry");
    const communityRegistryInstance = await communityRegistryFactory.attach(communitiesRegistryAddress);

    const chainLinkAddress = await communityRegistryInstance.getChainlinkToken();

    console.log("CHAINLINK ADDRESS", chainLinkAddress);
    console.log("TOKEN ADDRESS", config.linkAddress[config.defaultNetwork]);



};


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
