const partnersRegistryAddress = '0xEF76e657CE2b5a764a1707FdF23CeDf022BE64c4'
const distributedTownAddress = '0x71aa16bF81407265956EFf5540F3D4B8D72F3982'

const { assert } = require('chai')
const fs = require("fs");

var ethers = require('ethers')

var partnersRegistryAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersRegistry.sol/PartnersRegistry.json')
    .abi
var partnersAgreementAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersAgreement.sol/PartnersAgreement.json')
    .abi
var membershipAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/Membership.sol/Membership.json')
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

// create(string calldata url, uint256 role)
async function createMembershipCard(partnersAgreementAddress, skillWalletId) {
    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddress,
        partnersAgreementAbi,
        signer,
    )

    const membershipAddress = await partnersAgreementContract.membershipAddress();
    console.log('membershipAddress', membershipAddress)
    const membershipContract = new ethers.Contract(
        membershipAddress,
        membershipAbi,
        signer,
    )
    const createTx = await membershipContract.create(
        'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq', 2)
    await createTx.wait();

    const membershipID = await membershipContract.skillWalletToMembershipID(skillWalletId);
    console.log('membershipID:', membershipID);
}


async function test() {
    // await setPartnersRegistryAddress();
    // await createPartnersAgreement();

    // partnersAgreementAddress: '0xe470927feF4Aa20798C71fA43DDd5329D6162789',
    // communityAddress: '0xb05Ee1F1B4E3cA8C5E7363C9004951341c669929'

    await createMembershipCard('0xe470927feF4Aa20798C71fA43DDd5329D6162789', 5);
    // await activatePA('0xe470927feF4Aa20798C71fA43DDd5329D6162789')
    // await isActive('0xe470927feF4Aa20798C71fA43DDd5329D6162789');
}

test()