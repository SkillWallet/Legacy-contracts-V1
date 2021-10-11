/* eslint no-use-before-define: "warn" */
const chalk = require("chalk");
const { ethers, upgrades } = require("hardhat");


const main = async () => {

    console.log("\n\n 📡 Deploying...\n");

    const RoleUtils = await ethers.getContractFactory('RoleUtils');
    const roleUtils = await RoleUtils.deploy();
    await roleUtils.deployed();
    console.log('roleUtilsAddress', roleUtils.address)

    const PartnersRegistry = await ethers.getContractFactory('PartnersRegistry', {
        libraries: {
            RoleUtils: roleUtils.address
        }
    });

    const oracleMumbai = '0xc8D925525CA8759812d0c299B90247917d4d4b7C';
    const linkTokenMumbai = '0x326C977E6efc84E512bB9C30f76E30c160eD06FB';
    const distributedTownAddress = "0xbd3e6c9213eF3b90D6e31AfBbd5021c0f37046ff";

    const partnersRegistry = await upgrades.deployProxy(PartnersRegistry, [distributedTownAddress, oracleMumbai, linkTokenMumbai], {
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
