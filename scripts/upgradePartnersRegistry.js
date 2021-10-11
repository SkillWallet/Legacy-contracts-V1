const { ethers, upgrades } = require('hardhat');

async function main () {

  const partnersRegistryProxyAddress = '0x2d5F9858a1656163327908D623cfe1255fd589Fa';
  const roleUtilsAddress = '0x2ee1E59FaA15a23882275b360E844dC885E03B6D';


  const PartnersRegistry = await ethers.getContractFactory('PartnersRegistry', {
    libraries: {
        RoleUtils: roleUtilsAddress
    }
});

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
