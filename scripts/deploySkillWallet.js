/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers } = require("hardhat");
const { deploy } = require("./utils")

const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    
    const linkTokenMumbai = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    // const linkTokenKovan = '0xa36085f69e2889c224210f603d836748e7dc0088';
    // const oracleKovan = '0xF405B99ACa8578B9eb989ee2b69D518aaDb90c1F';
    const oracleMumbai = '0xc8D925525CA8759812d0c299B90247917d4d4b7C'
  
    const skillWallet = await deploy("SkillWallet", [linkTokenMumbai, oracleMumbai]);

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
