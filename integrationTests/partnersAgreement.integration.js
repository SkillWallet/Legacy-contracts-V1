const partnersRegistryAddress = '0x95488fA2A8CF3e80815A32D06439078974e548B4'
const distributedTownAddress = '0xbd3e6c9213eF3b90D6e31AfBbd5021c0f37046ff'
// const partnersRegistryAddress = '0x7a95A9f0A99fb21548e58821059502C85c193956';
// const distributedTownAddress = '0xf628bdee30627558aAe8c19d1522b08A2bfb6423';
const partnersAgreementAddress = '0xB1102D8F28d3dfEF7e50A46b4fD51fEC7Db4C93c';
const communityAddress = '0x200E16f678Ef8225A80e6b86495944c5a62cBB87';

const { assert } = require('chai')
const fs = require("fs");

var ethers = require('ethers')
var partnersRegistryAbi = require('../artifacts/contracts/main/partnersAgreement/PartnersRegistry.sol/PartnersRegistry.json')
  .abi

var partnersAgreementAbi = require('../artifacts/contracts/main/partnersAgreement/PartnersAgreement.sol/PartnersAgreement.json')
  .abi
var distributedTownAbi = require('../artifacts/contracts/imported/IDistributedTown.sol/IDistributedTown.json')
  .abi
var communityAbi = require('../artifacts/contracts/imported/ICommunity.sol/ICommunity.json')
  .abi

const userAddress = '0x2CEF62C91Dd92FC35f008D1d6Ed08EADF64306bc';

const provider = new ethers.providers.JsonRpcProvider(
  'https://rpc-mumbai.maticvigil.com/v1/9ca44fbe543c19857d4e47669aae2a9774e11c66'

)

// Wallet connected to a provider
const senderWalletMnemonic = ethers.Wallet.fromMnemonic(
  "m/44'/60'/0'/0/0"
);

let signer = senderWalletMnemonic.connect(provider)

const partnersRegistryContract = new ethers.Contract(
  partnersRegistryAddress,
  partnersRegistryAbi,
  signer,
)


const communityContract = new ethers.Contract(
  communityAddress,
  communityAbi,
  signer,
)

const ditoContract = new ethers.Contract(
  distributedTownAddress,
  distributedTownAbi,
  signer,
)

const partnersAgreementContract = new ethers.Contract(
  partnersAgreementAddress,
  partnersAgreementAbi,
  signer,
)

async function join() {
  const createTx = await communityContract.joinNewMember(
    '',
    '2000000000000000000000',
    { gasPrice: 1000000000, gasLimit: 850000 }
  )
  const res = await createTx.wait()
  console.log(res);
}

async function trigerTxQuery() {
  const createTx = await partnersAgreementContract.queryForNewInteractions(
    '0x27c3d6E3Bf8d6a19165eFFB6E265121FE234EEBF',
    { gasPrice: 1000000000, gasLimit: 850000 }
  )
  const res = await createTx.wait()
  console.log(res);
}

async function setPartnersRegistryAddress() {
  const createTx = await ditoContract.setPartnersRegistryAddress(
    partnersRegistryAddress
  )
  const res = await createTx.wait()
}
async function createPartnersAgreement() {
  const url =
    'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq'
  const createTx = await partnersRegistryContract.create(
    url,
    1,
    3,
    100,
    '0x1d08c93724741eE0E43ac9D623A127F48B16c2a8',
    50

  )
  const createTxResult = await createTx.wait()
  const { events } = createTxResult
  console.log(events);
  const pa = events.logs[0].args[0];
  const partnersAgreementCreatedEventEmitted = events.find(
    (e) => e.event === 'PartnersAgreementCreated',
  )

  assert.isOk(
    partnersAgreementCreatedEventEmitted,
    'PartnersAgreementCreated event emitted',
  )

  return pa;
}

async function activatePA() {


  const partnersAgreementContract = new ethers.Contract(
    partnersAgreementAddress,
    partnersAgreementAbi,
    signer,
  )

  const isActiveBefore = await partnersAgreementContract.isActive();

  assert.isFalse(
    isActiveBefore,
    'Not active before activation.',
  )
  const createTx = await partnersAgreementContract.activatePA();
  await createTx.wait()

  const isActiveAfter = await partnersAgreementContract.isActive();

  assert.isTrue(
    isActiveAfter,
    'Activated!',
  )
}


async function isActive() {


  const partnersAgreementContract = new ethers.Contract(
    partnersAgreementAddress,
    partnersAgreementAbi,
    signer,
  )

  const isActive = await partnersAgreementContract.isActive();
  console.log('isActive', isActive)
}


async function test() {
  // await setPartnersRegistryAddress();
  // await createPartnersAgreement()
  // await join();
  // await activatePA()
  // await isActive();
  await trigerTxQuery();
}

test()


// partnersAgreementAddress: '0xDB29E7D4598C164aE78a1a4075320Acb46d64D8d',
// communityAddress: '0xC77406a6fA434dBDF64dD6e18745240De50cfbe4'