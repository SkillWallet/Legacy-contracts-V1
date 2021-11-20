/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers, upgrades } = require("hardhat");


const main = async () => {

    console.log("\n\n 📡 Deploying...\n");

    const RoleUtils = await ethers.getContractFactory('RoleUtils');
    const roleUtils = await RoleUtils.deploy();
    await roleUtils.deployed();
    console.log('roleUtilsAddress', roleUtils.address)

    const PartnersRegistry = await ethers.getContractFactory('PartnersRegistry');
    const MembershipFactory = await ethers.getContractFactory('MembershipFactory');
    const PartnersAgreementFactory = await ethers.getContractFactory('PartnersAgreementFactory');
    const membershipFactory = await MembershipFactory.deploy(1);
    await membershipFactory.deployed();
    const partnersAgreementFactory = await PartnersAgreementFactory.deploy(1);
    await partnersAgreementFactory.deployed();

    const oracleMumbai = '0xc8D925525CA8759812d0c299B90247917d4d4b7C';
    const linkTokenMumbai = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    const distributedTownAddress = "0x71aa16bF81407265956EFf5540F3D4B8D72F3982";

    const partnersRegistry = await upgrades.deployProxy(PartnersRegistry, [
        distributedTownAddress,
        partnersAgreementFactory.address,
        membershipFactory.address,
        oracleMumbai,
        linkTokenMumbai
    ], {
        initializer: 'initialize',
        unsafeAllowLinkedLibraries: true
    });
    await partnersRegistry.deployed();

    console.log('PartnersReigstry deployed to:', partnersRegistry.address);
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
