const { ethers, upgrades } = require('hardhat');

async function main () {

  const partnersRegistryProxyAddress = '0x1ba41241b3f25cc7106de8ca462ecF6912A4e978';

  const PartnersRegistry = await ethers.getContractFactory('PartnersRegistry');
  const skillWalletAddress = '0x433577c845478F6b9Cc6dc0B54a5E6B3c8C125E9'
  const PartnersAgreementFactory = await ethers.getContractFactory('PartnersAgreementFactory');
  const InteractionFactory = await ethers.getContractFactory("InteractionNFTFactory");
  const interactionFactory = await InteractionFactory.deploy();
  await interactionFactory.deployed();
  const partnersAgreementFactory = await PartnersAgreementFactory.deploy(4, interactionFactory.address);
  await partnersAgreementFactory.deployed();

  console.log(partnersAgreementFactory.address);
  console.log('Upgrading PartnersRegistry...');
//   await upgrades.upgradeProxy(partnersRegistryProxyAddress, PartnersRegistry, [
//     skillWalletAddress,
//     partnersAgreementFactory.address,
// ], {
//     initializer: 'initialize',
//     unsafeAllowLinkedLibraries: true
// });
  console.log('PartnersRegistry upgraded');
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
