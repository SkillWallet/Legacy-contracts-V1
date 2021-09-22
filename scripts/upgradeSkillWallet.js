const { ethers, upgrades } = require('hardhat');

async function main () {
    console.log(await ethers.provider.getBlockNumber())

  const SkillWallet = await ethers.getContractFactory('SkillWallet');
  console.log('Upgrading SkillWallet...');
  await upgrades.upgradeProxy('0xbc83Dff75363161616729B760AB8814c8CD55D1c', SkillWallet);
  console.log('SkillWallet upgraded');
}


main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
