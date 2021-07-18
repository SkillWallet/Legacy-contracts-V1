const skillWalletAddress = '0x7426575fa17c319ca85591a1211E5574f49694aB'
const communityAddress = '0xC79c95236d2A876205D36cE4b160cFA4397dDA9C'
const { assert } = require('chai')
var ethers = require('ethers')
var abi = require('../artifacts/contracts/main/SkillWallet.sol/SkillWallet.json')
  .abi
var communityAbi = require('./communityAbi')
const helpers = require('../test/helpers')
const memberAddress = '0x2CEF62C91Dd92FC35f008D1d6Ed08EADF64306bc'
function mnemonic() {
  return 'close gesture fatal vacant time toy general horror payment visit case you'
}



const keyPair = {
  privKey: new Buffer([
    142,
    252,
    198,
    63,
    45,
    98,
    39,
    115,
    124,
    60,
    235,
    10,
    91,
    68,
    135,
    180,
    231,
    31,
    64,
    80,
    87,
    41,
    92,
    78,
    194,
    51,
    48,
    220,
    180,
    116,
    64,
    170,
  ]),
  pubKey: '440ac41f7fa85a68697877fff22217ace116cd56164ec4a5d6ddd675d03b1eaf',
}

const provider = new ethers.providers.JsonRpcProvider(
  'https://kovan.infura.io/v3/779285194bd146b48538d269d1332f20',
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
  const newKeyPair = generateKeyPair();
  keyPair = newKeyPair;

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

async function validateSW(tokenId, action) {
  const nonce = await helpers.getNonce(tokenId, 0)
  const signature = await helpers.sign(keyPair.privKey, nonce)
  const validationTx = await skillWalletContract.validate(
    signature,
    tokenId,
    action,
    [],
    [],
    [],
  )

  console.log(validationTx)
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
  return requestId
}

async function hasValidationPassed(reqId) {
  const validationPassed = await skillWalletContract.isRequestIdValid(reqId)
  assert.isTrue(validationPassed, 'Validation has passed.')
}

async function isSkillWalletActivated(tokenId) {
  const isActivated = await skillWalletContract.isSkillWalletActivated(tokenId)
  console.log('isActivated:', isActivated)
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

async function getLogins(nonce) {
  const logins = await getLogin(nonce);
  console.log(logins);
}

async function test() {
  // const tokenId = await joinCommunity()
  const tokenId = 5
  getLogins('123123');
  // await addPubKeyToSkillWallet(tokenId)
  // const reqId = await validateSW(tokenId, 0);
  // await isSkillWalletActivated(tokenId)
  // console.log(
  //   '[sleep]',
  //   'waiting 10 seconds for the chainlink validation to pass',
  // )
  // await sleep(10000)
  // await hasValidationPassed(reqId)
  // await isSkillWalletActivated(tokenId)
}

test()
