/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");


const joinNewMember = async (communityRegistryInstance, communityAddress, memberAddress) => {

    let oneBn = ethers.BigNumber.from(1);
    await communityRegistryInstance.joinNewMember(communityAddress, memberAddress, ethers.BigNumber.from(28), ethers.BigNumber.from(8), ethers.BigNumber.from(30), ethers.BigNumber.from(8), ethers.BigNumber.from(24), ethers.BigNumber.from(10), 'abcde')

}

const main = async () => {
    const communitiesRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];
    const communityAddress =  config.communityAddress[config.defaultNetwork];
    const memberAddress = "0x9CF7fD7ACD70E849629CdE0C2bcd7D77E5743f86";

    console.log("\n\n 📡 Deploying...\n");

    //
    const communityRegistryFactory = await ethers.getContractFactory("CommunitiesRegistry");
    const communityRegistryInstance = await communityRegistryFactory.attach(communitiesRegistryAddress);


    await joinNewMember(communityRegistryInstance, communityAddress, memberAddress)

};


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
