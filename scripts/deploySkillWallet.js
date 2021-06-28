/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers } = require("hardhat");
const { deploy } = require("./utils")

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    
    const linkToken = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    const oracle = '0xc8D925525CA8759812d0c299B90247917d4d4b7C';
  
    const skillWallet = await deploy("SkillWallet", [linkToken, oracle]);

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
