var eccryptoJS = require('eccrypto-js');
var axios = require('axios');

const generateKeyPair = () => {
    const key = eccryptoJS.generateKeyPair();
    const hex = key.publicKey.toString('hex');

    const hashed = eccryptoJS.keccak256(Buffer.from(hex));
    const pubKey = eccryptoJS.bufferToHex(hashed);

    return { pubKey, privKey: key.privateKey }
}

const getNonce = async (skillWalletId, action) => {
    const res = await axios.post(`https://api.skillwallet.id/api/skillwallet/${skillWalletId}/nonces?action=${action}`);
    const nonce = res.data.nonce.toString();
    return nonce;
}
const getLogin = async (nonce) => {
    const res = await axios.get(`https://api.skillwallet.id/api/skillwallet/login?nonce=${nonce}`);
    return res.data;
}

const sign = async (privKey, msg) => {
    const hashedMessage = await eccryptoJS.sha256(msg);
    const signed = eccryptoJS.sign(privKey, hashedMessage, true);
    const signature = eccryptoJS.bufferToHex(signed);
    return signature;
}

exports.sign = sign;
exports.getLogin = getLogin;
exports.getNonce = getNonce;
exports.generateKeyPair = generateKeyPair;
