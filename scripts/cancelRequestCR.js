/* eslint no-use-before-define: "warn" */
const { config, ethers } = require("hardhat");


const main = async () => {
    const communityRegistryAddress = config.communityRegistryAddress[config.defaultNetwork];

    const communityRegistryFactory = await ethers.getContractFactory("CommunitiesRegistry");
    const communityRegistryInstance = await communityRegistryFactory.attach(communityRegistryAddress);

    await communityRegistryInstance.cancelRequest();
};


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
