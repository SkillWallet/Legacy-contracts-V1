const { ethers, upgrades } = require('hardhat');

async function main () {

  const partnersRegistryProxyAddress = '0x71165fc407ff1c139Ef7ABE9181766bc9090a685';

  const PartnersRegistry = await ethers.getContractFactory('PartnersRegistry');
  const skillWalletAddress = '0xc73eAC76Ff73D39f94F1455e807c17611ECF8D56'
  const PartnersAgreementFactory = await ethers.getContractFactory('PartnersAgreementFactory');
  const InteractionFactory = await ethers.getContractFactory("InteractionNFTFactory");
  const interactionFactory = await InteractionFactory.deploy();
  await interactionFactory.deployed();
  const partnersAgreementFactory = await PartnersAgreementFactory.deploy(4, interactionFactory.address);
  await partnersAgreementFactory.deployed();

  console.log(partnersAgreementFactory.address);
  console.log('Upgrading PartnersRegistry...');
  await upgrades.upgradeProxy(partnersRegistryProxyAddress, PartnersRegistry, {
    initializer: 'initialize',
    unsafeAllowLinkedLibraries: true
});
  console.log('PartnersRegistry upgraded');
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
