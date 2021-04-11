/* eslint no-use-before-define: "warn" */
const { config, ethers } = require("hardhat");


const main = async () => {
    const deployerWallet = ethers.provider.getSigner();
    const deployerWalletAddress = await deployerWallet.getAddress();
    const communityAddress = config.communityAddress[config.defaultNetwork];

    const communityFactory = await ethers.getContractFactory("Community");
    const communityInstance = await communityFactory.attach(communityAddress);
    const memberAddress = "0x9CF7fD7ACD70E849629CdE0C2bcd7D77E5743f86";

    const credits = await communityInstance.balanceOf(memberAddress, ethers.BigNumber.from(0));

    console.log("Credits", credits.toString())


};

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
