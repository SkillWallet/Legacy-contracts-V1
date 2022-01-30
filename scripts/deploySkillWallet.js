/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers, upgrades } = require("hardhat");

const main = async () => {

    const SkillWallet = await ethers.getContractFactory('SkillWallet');
    console.log('Deploying SkillWallet...');
        
    const linkTokenMumbai = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    const oracleMumbai = '0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb'

    const linkTokenPolygon = '0xb0897686c545045afc77cf20ec7a532e3120e0f1';
    const oraclePolygon = '0x0a31078cD57d23bf9e8e8F1BA78356ca2090569E'

    const skillWallet = await upgrades.deployProxy(SkillWallet, [linkTokenMumbai, oracleMumbai], { initializer: 'initialize' });
    await skillWallet.deployed();
    console.log('SkillWallet deployed to:', skillWallet.address);

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
