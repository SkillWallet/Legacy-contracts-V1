/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");


const joinNewMember = async (communityRegistryInstance, communityAddress, memberAddress) => {

    let oneBn = ethers.BigNumber.from(1);
    await communityRegistryInstance.joinNewMember(communityAddress, memberAddress, oneBn, oneBn, oneBn, oneBn, oneBn, oneBn, '')

}

const main = async () => {
    const communitiesRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];
    const communityAddress =  config.communityAddress[config.defaultNetwork];
    const memberAddress = "0x85E537A931Ed30F425cb75829796744bB0A15D71";

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
