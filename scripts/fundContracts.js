/* eslint no-use-before-define: "warn" */
const fs = require("fs");
const chalk = require("chalk");
const { config, ethers, tenderly, run } = require("hardhat");
const { utils } = require("ethers");
const R = require("ramda");

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const linkAddress = config.linkAddress[config.defaultNetwork];
    const LINK_TOKEN_ABI = [{ "inputs": [{ "internalType": "address", "name": "recipient", "type": "address" }, { "internalType": "uint256", "name": "amount", "type": "uint256" }], "name": "transfer", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "nonpayable", "type": "function" }]

    const skillWalletContractAddress = config.skillWalletAddress[config.defaultNetwork];
    const communityRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];

    //Create connection to LINK token contract and initiate the transfer
    const linkTokenContract = new ethers.Contract(linkAddress, LINK_TOKEN_ABI, deployerWallet)

    const amount = ethers.utils.parseEther("0.1")

    const res1 = await linkTokenContract.transfer(skillWalletContractAddress, amount)
    const res2 = await linkTokenContract.transfer(communityRegistryAddress, amount)

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
