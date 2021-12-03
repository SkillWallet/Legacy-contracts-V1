// const skillWalletAddress = '0x1e79bE396CE37F7eB43aF0Ef0ffb3124F3fD23eF'
const skillWalletAddress = '0xd43696bAc9B4331f18b71c0F80DD56aEc130B808' // upgradable
const dito = '0xe60a5C15Cf3C4F820f9771Ea68dA8CE41376B577'
// const communityAddress = '0xec1380558d5A9e25bf258f2e341C6bF562ca7480'
const communityAddress = '0xCBD8DA830262a287d73fF3eF07b0A0b350453C00' //upgradable SW
const { assert } = require('chai')
var ethers = require('ethers')
var abi = require('../artifacts/contracts/main/SkillWallet.sol/SkillWallet.json')
  .abi

var osmAbi = require('../artifacts/contracts/main/OSM.sol/OffchainSignatureMechanism.json')
  .abi
var communityAbi = require('./communityAbi')
const helpers = require('../test/helpers')
const fs = require("fs");

function mnemonic() {
  try {
    return fs.readFileSync("./mnemonic.txt").toString().trim();
  } catch (e) {
    console.log(e);
  }
  return "";
}



let keyPair = {
  pubKey: '0442f1fa140d9fcb8ddca188ffc83d1512bcb3be4de464512169c4555f3f7a6ca5e3afb51f7604cdbbf4234b6958852d0b4c57b0ba18af4350a652e889f7f6660a',
}

const provider = new ethers.providers.JsonRpcProvider(
  // 'https://kovan.infura.io/v3/779285194bd146b48538d269d1332f20',
  'https://rpc-mumbai.maticvigil.com/'
)

// Wallet connected to a provider
const senderWalletMnemonic = ethers.Wallet.fromMnemonic(
  mnemonic(),
  "m/44'/60'/0'/0/0",
)

let signer = senderWalletMnemonic.connect(provider)

const skillWalletContract = new ethers.Contract(skillWalletAddress, abi, signer)

const communityContract = new ethers.Contract(
  communityAddress,
  communityAbi,
  signer,
)


async function joinCommunity() {
  // const newKeyPair = helpers.generateKeyPair();
  // keyPair = newKeyPair;

  const url =
    'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq'
  const wei = ethers.utils.parseEther('2220').toString()
  const joinedTx = await communityContract.joinNewMember(
    url,
    1,
    wei,
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

async function addPubKeyToSkillWallet(tokenId) {
  const addPubKeyTx = await skillWalletContract.addPubKeyToSkillWallet(
    tokenId,
    keyPair.pubKey,
  )

  // Wait for transaction to finish
  const addPubKeyTxResult = await addPubKeyTx.wait()
  const { events } = addPubKeyTxResult
  const addPubKeyEventEmitted = events.find(
    (e) => e.event === 'PubKeyAddedToSkillWallet',
  )

  const pubKey = await skillWalletContract.skillWalletToPubKey(tokenId)

  assert.equal(pubKey, keyPair.pubKey, 'PubKey is correctly stored;')
  console.log('[addPubKeyToSkillWallet]:', 'PubKey is correctly stored')
  assert.isOk(addPubKeyEventEmitted, 'PubKeyAddedToSW event emitted')
  console.log('[addPubKeyToSkillWallet]:', 'PubKeyAddedToSW event emitted')
}

async function claim() {
  const claimTx = await skillWalletContract.claim();

  const claimTxResult = await claimTx.wait()
  const { events } = claimTxResult
  const claimEventEmitted = events.find(
    (e) => e.event === 'SkillWalletClaimed'
  );

  if (claimEventEmitted) {
    console.log('[Claim]:', 'Finished Successfully');
  } else {
    console.log('[Claim]:', 'Failed');
  }
}



async function addDiscordID() {
  const addDiscordIDTx = await skillWalletContract.addDiscordIDToSkillWallet('migrenaa#4690');

  const addDiscordIDTxResult = await addDiscordIDTx.wait()
  const { events } = addDiscordIDTxResult
  const discordIDAddedEventEmitted = events.find(
    (e) => e.event === 'DiscordIDConnectedToSkillWallet'
  );

  if (discordIDAddedEventEmitted) {
    console.log('[DiscordIDConnectedToSkillWallet]:', 'Finished Successfully');
  } else {
    console.log('[DiscordIDConnectedToSkillWallet]:', 'Failed');
  }
}

async function getOSMAddr() {
  const osmAddr = await skillWalletContract.getOSMAddress();
  console.log(osmAddr);
}


async function getCommunityAddress() {
  const a = await part
}
async function validateSW(tokenId, action, nonce) {
  const osmAddr = await skillWalletContract.getOSMAddress();

  const osmContract = new ethers.Contract(
    osmAddr,
    osmAbi,
    signer
  )

  if (!nonce)
    nonce = await helpers.getNonce(tokenId, action)
  // const signature = await helpers.sign(keyPair.privKey, nonce.toString())
  const signature = '304402207f6139c3fb2772e43c6a43ed1ff7205d29386d44415bb4307455aa87a3362ab4022072a926ba8eedd169760c96911043b538a477089f20044985506fa4d5c20f0bc2';
  const validationTx = await osmContract.validate(
    signature,
    tokenId,
    action,
    [],
    [],
    [],
  )

  // Wait for transaction to finish
  const validationTxResult = await validationTx.wait()
  const { events } = validationTxResult
  const validationEventEmitted = events.find(
    (e) => e.event === 'ValidationRequestIdSent',
  )
  const requestId = validationEventEmitted.args[0]

  assert.isOk(validationEventEmitted, 'ValidationRequestIdSent event emitted')
  console.log('[validateSW]:', 'ValidationRequestIdSent event emitted')
  assert.isOk(requestId, 'requestId not empty')
  console.log('[validateSW]:', 'requestId not empty')
  return { requestId, nonce }
}

async function hasValidationPassed(reqId) {
  const validationPassed = await skillWalletContract.isRequestIdValid(reqId)
  assert.isTrue(validationPassed, 'Validation has passed.')
}

async function isSkillWalletActivated(tokenId) {
  const isActivated = await skillWalletContract.isSkillWalletActivated(tokenId)
  console.log('isActivated:', isActivated)
}

async function getmetadata(tokenId) {
  const isActivated = await communityContract.metadataUri()
  console.log('isActivated:', isActivated)
}
function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function getLogins(nonce) {
  const logins = await helpers.getLogin(nonce);
  console.log(logins);
}

async function getCommunity(tokenID) {
  const com = await skillWalletContract.getActiveCommunity(tokenID);
  console.log('[active community]', com);
}

async function test() {
  // await getOSMAddr();
  const tokenId = 14;
  
  // await getCommunity(tokenId);
  // // // const tokenId = await joinCommunity()
  // // // await claim();

  // await addPubKeyToSkillWallet(tokenId)
  // const activateRes = await validateSW(tokenId, 0);
  // await isSkillWalletActivated(tokenId)
  // console.log(
  //   '[sleep]',
  //   'waiting 10 seconds for the chainlink validation to pass',
  // )
  // await sleep(10000)
  // await isSkillWalletActivated(tokenId)

  // await getmetadata(tokenId)
  // await addDiscordID();
}

test()
