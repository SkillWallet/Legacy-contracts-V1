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
    const InteractionFactory = await ethers.getContractFactory("InteractionNFTFactory");
    const interactionFactory = await InteractionFactory.deploy();
    await interactionFactory.deployed();

    const partnersAgreementFactory = await PartnersAgreementFactory.deploy(1, interactionFactory.address);
    await partnersAgreementFactory.deployed();

    const skillWalletAddress = ''

    const partnersRegistry = await upgrades.deployProxy(PartnersRegistry, [
        skillWalletAddress,
        partnersAgreementFactory.address,
        membershipFactory.address,
        '0x655c5f51266c741BefD8fc4Bb7B5450E21C02006'
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
