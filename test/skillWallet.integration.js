const skillWalletAddress = '0x698f51C10fa47bE854E974C2b526D5288e0Bd5A7'
const communityAddress = '0x0d296ccE6992A42fb51F77fa08bfe7C62F89201A'
const { assert } = require('chai')
var ethers = require('ethers')
var abi = require('../artifacts/contracts/main/SkillWallet.sol/SkillWallet.json')
  .abi
var communityAbi = require('../artifacts/contracts/mocks/Community.sol/Community.json')
  .abi
const helpers = require('./helpers')
const memberAddress = '0x2CEF62C91Dd92FC35f008D1d6Ed08EADF64306bc';
function mnemonic() {
  return "";
}

const provider = new ethers.providers.JsonRpcProvider(
  'https://rpc-mumbai.maticvigil.com',
)

// Wallet connected to a provider
const senderWalletMnemonic = ethers.Wallet.fromMnemonic(
  mnemonic(),
  "m/44'/60'/0'/0/0",
)

const keyPair = helpers.generateKeyPair()
console.log('KeyPair generated');

let signer = senderWalletMnemonic.connect(provider)

const skillWalletContract = new ethers.Contract(skillWalletAddress, abi, signer)

const communityContract = new ethers.Contract(
  communityAddress,
  communityAbi,
  signer,
)

async function joinCommunity() {
  const url =
    'https://hub.textile.io/ipfs/bafkreicezefuc6einewxdqhlpefelzjponwdqt4vmp2byosq5uwpn7hgoq'
  const wei = ethers.utils.parseEther('2220').toString()
  const joinedTx = await communityContract.joinNewMember(
    1,
    1,
    2,
    2,
    3,
    3,
    url,
    wei,
  )
  const joinCommunityTxResult = await joinedTx.wait()
  const { events } = joinCommunityTxResult
  const memberAddedEventEmitted = events.find((e) => e.event === 'MemberAdded');

  assert.isOk(memberAddedEventEmitted, 'MemberAdded event emitted');
  console.log('[joinCommunity]:', 'MemberAdded event emitted')
  assert.isAbove(+memberAddedEventEmitted.args[1], -1, 'TokenID is valid');
  console.log('[joinCommunity]:', 'TokenID is valid')
  return memberAddedEventEmitted.args[1];

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

  const pubKey = await skillWalletContract.skillWalletToPubKey(tokenId);

  assert.equal(pubKey, keyPair.pubKey, 'PubKey is correctly stored;');
  console.log('[addPubKeyToSkillWallet]:', 'PubKey is correctly stored')
  assert.isOk(addPubKeyEventEmitted, 'PubKeyAddedToSW event emitted');
  console.log('[addPubKeyToSkillWallet]:', 'PubKeyAddedToSW event emitted')
}

async function validateSW(tokenId) {
  const nonce = await helpers.getNonce(tokenId, 0);
  const signature = await helpers.sign(keyPair.privKey, nonce);
  const validationTx = await skillWalletContract.validate(
    signature,
    tokenId,
    0,
    [],
    [],
    [],
  )
  // Wait for transaction to finish
  const validationTxResult = await validationTx.wait()
  const { events } = validationTxResult
  const validationEventEmitted = events.find((e) => e.event === 'ValidationRequestIdSent');
  const requestId = validationEventEmitted.args[0];

  assert.isOk(validationEventEmitted, 'ValidationRequestIdSent event emitted');
  console.log('[validateSW]:', 'ValidationRequestIdSent event emitted')
  assert.isOk(requestId, 'requestId not empty');
  console.log('[validateSW]:', 'requestId not empty')
  return requestId;
}

async function hasValidationPassed(reqId) {
  const validationPassed = await skillWalletContract.isRequestIdValid(reqId);
  assert.isTrue(validationPassed, 'Validation has passed.');
}

async function isSkillWalletActivated(tokenId) {
  const isActivated = await skillWalletContract.isSkillWalletActivated(tokenId)
  console.log('isActivated:', isActivated)
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function test() {
  const tokenId = await joinCommunity();
  await addPubKeyToSkillWallet(tokenId);
  const reqId = await validateSW(tokenId);
  await isSkillWalletActivated(tokenId);
  console.log('[sleep]', 'waiting 10 seconds for the chainlink validation to pass')
  await sleep(10000);
  await hasValidationPassed(reqId);
  await isSkillWalletActivated(tokenId);
}

test()
