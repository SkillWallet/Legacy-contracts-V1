/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers, upgrades } = require("hardhat");


const main = async () => {

    console.log("\n\n 📡 Deploying...\n");

    const ActivitiesFactory = await ethers.getContractFactory('Activities');

    const activitiesFactory = await ActivitiesFactory.deploy(['0x69Aa5A42559e45100EACfE56e6939e0a670Af2Ab', '0x8195cF28994814206096a4878892f3993955deb1']);

    await activitiesFactory.deployed();

    console.log('ActivitiesFactory deployed to:', activitiesFactory.address);
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
