/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");


const joinNewMember = async (communityRegistryInstance, communityAddress, memberAddress) => {

    let credits = ethers.utils.parseEther("2006");
    let oneBn = ethers.BigNumber.from(1);
    await communityRegistryInstance.joinNewMember(communityAddress, memberAddress, oneBn, oneBn, oneBn, oneBn, oneBn, oneBn, '')

}

const main = async () => {
    const communitiesRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];
    const communityAddress = "0x2f6519B04AdF148Ef851925626b07966e8736BAC";
    const memberAddress = "0xeAEdcA5E251B1e1D77F6928868B1Ad7Dd287356d";

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
