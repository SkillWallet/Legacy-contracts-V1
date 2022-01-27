const partnersRegistryAddress = '0x1ba41241b3f25cc7106de8ca462ecF6912A4e978'

const { assert } = require('chai')
const fs = require("fs");

var ethers = require('ethers')

var partnersRegistryAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersRegistry.sol/PartnersRegistry.json')
    .abi
var partnersAgreementAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersAgreement.sol/PartnersAgreement.json')
    .abi;
var communityAbi = require('../artifacts/contracts/main/Community.sol/Community.json')
    .abi;

function mnemonic() {
    try {
        return fs.readFileSync("./mnemonic.txt").toString().trim();
    } catch (e) {
        console.log(e);
    }
    return "";
}

function createWallet() {
    const wallet = ethers.Wallet.createRandom();
    console.log(wallet.address);
    console.log(wallet);
    console.log(wallet.privateKey);
    console.log(wallet.mnemonic);

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
        10,
        "0x0000000000000000000000000000000000000000",
        100,
        10,
        false
    );
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



async function migreatePA(partnersAgreementAddress) {
    await partnersRegistryContract.setVersion(5);
    const createTx = await partnersRegistryContract.migrate(
        partnersAgreementAddress, 
        true
    );
    // const createTxResult = await createTx.wait()
    // const { events } = createTxResult
    // console.log(events);
    // const partnersAgreementCreatedEventEmitted = events.find(
    //     (e) => e.event === 'PartnersAgreementCreated',
    // )

    // assert.isOk(
    //     partnersAgreementCreatedEventEmitted,
    //     'PartnersAgreementCreated event emitted',
    // )
    // return pa;
}


async function joinCommunity(communityAddress) {

    const communityContract = new ethers.Contract(
        communityAddress,
        communityAbi,
        signer,
    )
    const url =
        'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq'

    const joinedTx = await communityContract.joinNewMember(
        url,
        1
    )
    const joinCommunityTxResult = await joinedTx.wait()
    const { events } = joinCommunityTxResult
    const memberAddedEventEmitted = events.find((e) => e.event === 'MemberAdded')

    assert.isOk(memberAddedEventEmitted, 'MemberAdded event emitted')
    console.log('[joinCommunity]:', 'MemberAdded event emitted')
    assert.isAbove(+memberAddedEventEmitted.args[1], -1, 'TokenID is valid')
    console.log('[joinCommunity]:', 'TokenID is valid')
    return memberAddedEventEmitted.args[1]
}



async function addCoreTeamMember(communityAddress, memberAddress) {

    const communityContract = new ethers.Contract(
        communityAddress,
        communityAbi,
        signer,
    )

    // const newKeyPair = helpers.generateKeyPair();
    // keyPair = newKeyPair;
    const url =
        'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq'

    const joinedTx = await communityContract.addNewCoreTeamMembers(
        memberAddress
    );
    const joinCommunityTxResult = await joinedTx.wait()
    const { events } = joinCommunityTxResult
    const memberAddedEventEmitted = events.find((e) => e.event === 'CoreTeamMemberAdded')

    assert.isOk(memberAddedEventEmitted, 'CoreTeamMemberAdded event emitted')
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



async function isCoreTeamMember(communityAddress, user) {
    const communityContract = new ethers.Contract(
        communityAddress,
        communityAbi,
        signer,
    )

    const isCoreTeamMember = await communityContract.isCoreTeamMember(user);
    console.log('isCoreTeamMember', isCoreTeamMember)
}

async function getPAData(partnersAgreementAddr) {
    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddr,
        partnersAgreementAbi,
        signer,
    );
    const version = await partnersAgreementContract.version();
    console.log('version', version);
    const owner = await partnersAgreementContract.owner();
    console.log('owner', owner);

    const communityAddress = await partnersAgreementContract.communityAddress();
    console.log('communityAddress', communityAddress);
    const rolesCount = await partnersAgreementContract.rolesCount();
    console.log('rolesCount', rolesCount);
    const skillWallet = await partnersAgreementContract.getSkillWalletAddress();
    console.log('skillWallet', skillWallet);

}

async function setValueInTestMapping(partnersAgreementAddr) {

    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddr,
        partnersAgreementAbi,
        signer,
    );
     const a = await partnersAgreementContract.testMapping(101);
     console.log(a);
    //  await partnersAgreementContract.setValueInTestMapping(101, 202);
}


async function setValueInTestMappingCommunity(communityAddr) {

    const communityContract = new ethers.Contract(
        communityAddr,
        communityAbi,
        signer,
    );
    //  await communityContract.setValueInTestMapping(101, 202);
    //  const a = await communityContract.testMapping(101);
    //  console.log(a.toString());
}


async function test() {
    // await createPartnersAgreement();
    const partnersAgreementAddr = '0x27f0d9ddb8563bcF453974Bf29CE59Ba25a89DdD';
    const communityAddr = '0x07a0908C58A28B26234F642306627Cf1f9a4f845';

    const upgradedPA = '0x5976ec0e8ADD78775E9f5AF991CceF09E84492dd';
    const upgradedCom = '0xC8910046Eaa8FDFbCC28028d416Be33A51511aFa';


    // const tokenId = await joinCommunity(communityAddr);
    // const tokenId = 1;
    // console.log('old data');
    // await getPAData(partnersAgreementAddr);
    // console.log('new data');
    // console.log();
    // await getPAData(upgradedPA);

    // await setValueInTestMapping(upgradedPA);
    await setValueInTestMappingCommunity(upgradedCom)
    // await getPAs();
    // await activatePA(partnersAgreementAddr)
    // await isActive(upgradedPA);
    // await addCoreTeamMember(communityAddr, '0xEB77987d6125F5c7b6380DB422DBdF22bc4D6C18');
    // await isCoreTeamMember(communityAddr, '0xEB77987d6125F5c7b6380DB422DBdF22bc4D6C18')
    // await migreatePA(partnersAgreementAddr);
}

test()