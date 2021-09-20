/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers } = require("hardhat");
const { deploy } = require("./utils");

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    const distributedTownAddress = "0xB4E068Ea3f5086b76c3BC2Fbae4c5e59453207F8";

    console.log("\n\n 📡 Deploying...\n");


    const RoleUtils = await ethers.getContractFactory('RoleUtils');
    const roleUtils = await RoleUtils.deploy();
    await roleUtils.deployed();

    const oracleMumbai = '0xc8D925525CA8759812d0c299B90247917d4d4b7C';
    const linkTokenMumbai = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    const partnersRegistry = await deploy("PartnersRegistry", [distributedTownAddress, oracleMumbai, linkTokenMumbai], {}, {
        RoleUtils: roleUtils.address
    });
    await partnersRegistry.deployed();

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
