# Overview
The SkillWallet is a standard for universal, self-sovereign Identity as an NFT.<br/>
In order to receive it and activate individuals need to be member of a Community. By being part of a Community, they can participate Gigs/Tasks/Projects, that in return provide them Credits (DITO), that they can spend across the whole network, partners included.<br/>
Once an individual member's skills are validated (through Gigs), they will be able to spend their Credits, create new tasks/projects, and move to a different Community seamlessly, without losing the Credits & the reputation earned.

## Steps
Whenever new users start to create a new account, they are prompted to:
- select their main role or skills, plus a nickname and avatar
- based on their Skills selection, they can pick the Community they want to join
- these selections constitue the Metadata of their NFT ID, so that any Identity is initiated within a Community
- once the new SkillWallet ID is initiated, Chainlink Verifiable Random Function generates a unique hash that is added to the SkillWalletRegistry contract
- during the process, the new NFT ID is initially inactive, so the same VRF hash is used to generate a QR-code pattern, that is verifiably unique, and cannot be anyhow re-used or counterfaited
- at this point, new users will just download our SkillWallet Mobile App, and scan the QR-Code on the Web App.
- Finally, our Chainlink External Adapter will verify this action, and in just in 1 step, users new ID will be activated and they will receive their personal NFT ID – and own, de-facto, their universal, non-transferable, self-sovereign identity!

## Links
- [Video Demo](https://www.youtube.com/watch?v=L_67SfOAfQU)
- Try out the [Mobile App!](https://drive.google.com/drive/folders/1AsQ9ksHGGDLgCaIIodzkYRMl__QRpb9k?usp=sharing) (Android APK)

# Contracts

### 1. SkillWallet 
Location: `/contracts/main/SkillWallet.sol`
Addresses:
- Matic mainnet: `0x14DEF8Be678589dd1445A46Fc5bE925d479694B9`
- Matic testnet (Mumbai): `0xB0aD4014Ee360A2c7c668F2883ed73ae6780c817`
- RSK testnet: `0x5dDA86D336Aad78eDb8025902ab3DF8517df446E`

Smart contract used for SkillWallet management. Inherits from the ERC721 standard. Each SkillWallet is an NT-NFT (Non-transferable non-fungible token)
Uses Chainlink VRF (inherits from VRFConsumerBase) for creating random hash, used for QR code verification.
