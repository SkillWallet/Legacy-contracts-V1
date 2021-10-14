const partnersRegistryAddress = '0xb5E7878D3B3D64850d517A382C816beFce844328'
const distributedTownAddress = '0xA8d584D6503568636658CbD370E2895AAFF085a1'

// const partnersRegistryAddress = '0x7a95A9f0A99fb21548e58821059502C85c193956';
// const distributedTownAddress = '0xf628bdee30627558aAe8c19d1522b08A2bfb6423';
const partnersAgreementAddress = '0xb5515862dB3350436986ad1b35aB566C94732cE7';
const communityAddress = '0x43B2739FD3B39E3Be01e24627c60636793A3903F';

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


function mnemonic() {
  try {
      return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
      console.log(e);
  }
  return "";
}

const provider = new ethers.providers.JsonRpcProvider(
  'https://rpc-mumbai.maticvigil.com/v1/9ca44fbe543c19857d4e47669aae2a9774e11c66'

)

// Wallet connected to a provider
const senderWalletMnemonic = ethers.Wallet.fromMnemonic(
  mnemonic(),
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
