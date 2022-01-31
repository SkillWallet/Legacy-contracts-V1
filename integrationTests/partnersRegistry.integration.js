const partnersRegistryAddress = '0x59722BB9D2625ff16ebFc9ecD2492061414EeBC2'
const communityRegistryAddress = '0xA011B9161B2a14C83Df656B114407E8B7Eb25931'

const { assert } = require('chai')
const fs = require("fs");

var ethers = require('ethers')

var partnersRegistryAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersRegistry.sol/PartnersRegistry.json')
    .abi
var partnersAgreementAbi = require('../artifacts/contracts/main/partnersAgreement/contracts/PartnersAgreement.sol/PartnersAgreement.json')
    .abi;

var communityAbi = require('../artifacts/contracts/main/community/Community.sol/Community.json')
    .abi;

var communityRegistryAbi = require("../artifacts/contracts/main/community/CommunityRegistry.sol/CommunityRegistry.json")
    .abi;

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

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
    'https://polygon-rpc.com/'
    // 'https://matic-mumbai.chainstacklabs.com/'
)

// Wallet connected to a provider
const senderWalletMnemonic = ethers.Wallet.fromMnemonic(
    mnemonic(),
    "m/44'/60'/0'/0/0"
);


const url =
    'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq';

let signer = senderWalletMnemonic.connect(provider)

const partnersRegistryContract = new ethers.Contract(
    partnersRegistryAddress,
    partnersRegistryAbi,
    signer,
)

const communityRegistryContract = new ethers.Contract(
    communityRegistryAddress,
    communityRegistryAbi,
    signer
)

async function getPAs() {
    const createTx = await partnersRegistryContract.getPartnerAgreementAddresses(
    );
    console.log(createTx);
}
async function createCommunity() {
    const a = await (await communityRegistryContract.createCommunity(
        url,
        1,
        100,
        10,
        false,
        ZERO_ADDRESS
    )).wait();

    console.log('[createCommunity] communityAddr: ', a.events[0].args['comAddr']);
    return a.events[0].args['comAddr'];
}

async function createPartnersAgreement(comAddr) {

    const createTx = await partnersRegistryContract.create(
        comAddr,
        3,
        10,
        ZERO_ADDRESS,
        {
            gasLimit: 25000000
        }
    );

    const createTxResult = await createTx.wait()
    const { events } = createTxResult
    console.log(createTxResult);
    const partnersAgreementCreatedEventEmitted = events.find(
        (e) => e.event === 'PartnersAgreementCreated',
    )

    assert.isOk(
        partnersAgreementCreatedEventEmitted,
        'PartnersAgreementCreated event emitted',
    )
    console.log('PartnersAgreement: ', events[0].args['partnersAgreementAddress'])
    return events[0].args['partnersAgreementAddress'];
}


async function setPartnersAgreementFactory(factory) {
    const createTx = await partnersRegistryContract.setPAFactory(
        factory
    );
}


async function setVersion(version) {
    await partnersRegistryContract.setVersion(version);
}

async function migreatePA(partnersAgreementAddress) {
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


async function getComData(communityAddr) {
    const communityContract = new ethers.Contract(
        communityAddr,
        communityAbi,
        signer,
    );
    const version = await communityContract.version();
    console.log('version', version);
    const owner = await communityContract.owner();
    console.log('owner', owner);

    const communityAddress = await communityContract.template();
    console.log('template', communityAddress);
    const rolesCount = await communityContract.metadataUri();
    console.log('metadataUri', rolesCount);
    const skillWallet = await communityContract.getMemberAddresses();
    console.log('getMemberAddresses', skillWallet);

}

async function deployActivities(partnersAgreementAddr, factoryAddr) {

    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddr,
        partnersAgreementAbi,
        signer,
    );
    const a = await partnersAgreementContract.deployActivities(factoryAddr, {
        gasLimit: 25000000
    });
    console.log(a);
    console.log(await a.wait());
}



async function getActivities(partnersAgreementAddr) {

    const partnersAgreementContract = new ethers.Contract(
        partnersAgreementAddr,
        partnersAgreementAbi,
        signer,
    );
    console.log('isActive', await partnersAgreementContract.isActive());
    console.log('getActivitiesAddress', await partnersAgreementContract.getActivitiesAddress());
    console.log('interactionNFT', await partnersAgreementContract.interactionNFT());
    
}





async function test() {
    // const communityAddr = '0xFb0061886c317c68d1eE4a945b990BAdC3F01fB3';
    const partnersAgreementAddr = '0x762f2b2581F6D5E048bEd4815794fDF5aF6B5270';
    const activitiesFactory = '0x08B066886a4f1c226CE21b53d7CD53A092f060d5'
    //  await createCommunity();
    // await createPartnersAgreement(communityAddr);

    // await joinCommunity(communityAddr);

    // const tokenId = 1;
    // console.log('old data');
    // await getPAData(partnersAgreementAddr);
    // console.log('new data');
    // console.log();
    // await getPAData(upgradedPA);

    // await getPAs();
    // await getComData(communityAddr)
    // await getComData(upgradedCom)
    // await isActive(partnersAgreementAddr);
    // await addCoreTeamMember(communityAddr, '0x4e81dae01B6AFB743887C7AdE403a3d875594e8a');
    // await isCoreTeamMember(communityAddr, '0x4e81dae01B6AFB743887C7AdE403a3d875594e8a')
    // await migreatePA(partnersAgreementAddr);

    await deployActivities(partnersAgreementAddr, activitiesFactory);
    // await getActivities(partnersAgreementAddr);
    // await setVersion(2);
    // await setNewVar(upgradedCom)


    // await createWallet();
}

test()