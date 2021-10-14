const partnersRegistryAddress = '0xE245539DA46Cae8605146cc42D31Ab3BA0A87e9f'
const distributedTownAddress = '0xbd3e6c9213eF3b90D6e31AfBbd5021c0f37046ff'

const { assert } = require('chai')
const fs = require("fs");

var ethers = require('ethers')

var partnersRegistryAbi = require('../artifacts/contracts/main/partnersAgreement/PartnersRegistry.sol/PartnersRegistry.json')
    .abi
var partnersAgreementAbi = require('../artifacts/contracts/main/partnersAgreement/PartnersAgreement.sol/PartnersAgreement.json')
    .abi
var distributedTownAbi = require('../artifacts/contracts/imported/IDistributedTown.sol/IDistributedTown.json')
    .abi


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

const ditoContract = new ethers.Contract(
    distributedTownAddress,
    distributedTownAbi,
    signer,
)

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
    const partnersAgreementCreatedEventEmitted = events.find(
        (e) => e.event === 'PartnersAgreementCreated',
    )
    
    assert.isOk(
        partnersAgreementCreatedEventEmitted,
        'PartnersAgreementCreated event emitted',
    )

    return pa;
}

async function activatePA(partnersAgreementAddress) {
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


async function isActive(partnersAgreementAddress) {
    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddress,
        partnersAgreementAbi,
        signer,
    )

    const isActive = await partnersAgreementContract.isActive();
    console.log('isActive', isActive)
}


async function test() {

    const partnersAgreement = '0xCFD73b53e7aaFF0B699Be0e904018534b99FfC72'
    // await setPartnersRegistryAddress();
    // await createPartnersAgreement()
    await activatePA(partnersAgreement)
    await isActive(partnersAgreement);
}

test()