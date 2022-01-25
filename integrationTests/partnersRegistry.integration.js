const partnersRegistryAddress = '0x90836827F77E2402c78630f2295E3A828894885c'
const partnersAgreement = '0x13bfe76779F414222E72fb53Fc8D3c5A2573c573';
const { assert } = require('chai')
const fs = require("fs");

var ethers = require('ethers')

var partnersRegistryAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersRegistry.sol/PartnersRegistry.json')
    .abi
var partnersAgreementAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersAgreement.sol/PartnersAgreement.json')
    .abi
var membershipAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/Membership.sol/Membership.json')
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

async function getPAs() {
    const createTx = await partnersRegistryContract.getPartnerAgreementAddresses(
    );
    console.log(createTx);
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


async function getMemContract(partnersAgreementAddress) {
    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddress,
        partnersAgreementAbi,
        signer,
    )

    const membershipAddress = await partnersAgreementContract.getAgreementData();
    console.log('membershipAddress', membershipAddress)
}




async function isCoreTeamMember(partnersAgreementAddress, user) {
    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddress,
        partnersAgreementAbi,
        signer,
    )

    const isCoreTeamMember = await partnersAgreementContract.isCoreTeamMember(user);
    console.log('isCoreTeamMember', isCoreTeamMember)
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

    // await createMembershipCard('0xe470927feF4Aa20798C71fA43DDd5329D6162789', 5);
    // await activatePA('0xe470927feF4Aa20798C71fA43DDd5329D6162789')
    // await isActive(partnersAgreement);
    // await getMemContract(partnersAgreement);
    // await getPAs();
    await isCoreTeamMember('0x2f152fF9Edc8b99c3a5c018C95D5a4011627c409','0xCa05bcE175e9c39Fe015A5fC1E98d2B735fF51d9')
}

test()