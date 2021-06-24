# Overview
The SkillWallet is a permissionless, open-source protocol for the creation of universal, self-sovereign Identities - based on Skills instead of personal data. <br/>
It comes as an upgradable, Non-Transferable, Non-Fungible-Token (U-NT-NFT) - and it entiles native sybil-resistant properties. <br/>
Moreover, in order to receive their NT-NFT, individual users need to join a Community/Protocol/Platform. By being part of a Community, they can participate in Gigs/Tasks/Projects, that in return provide them Credits (DITO) - in the form of ERC777 - that they can spend across the whole network, including the Partners that integrate the SkillWallet package in their existing Contract. <br/>
Once an individual member's skills are validated (simply by contributing to Gigs), they will be able to spend their Credits, create new tasks/projects, and move to a different Community seamlessly, without losing the Credits & the reputation earned. <br/>
The sybyl-resistance features, together with the portability of the Skills & Benefits acquired, makes the SkillWallet the complementary missing piece in the Multiverse, and the NFT space at large.

## Steps
Behind the hoods, the protocol follows these steps:
- New SkillWallet ID is initiated as a Non-Transferable NFT (NT-NFT), within the community, and initially labeled inactive. 
- By installing the SkillWallet mobile app, a key pair is generated and the public key is stored on-chain and associated to the skill wallet token Id of the user.
- A unique nonce is generated and encoded in a QR code, shown on the Web App
- By scanning the QR code the mobile app signs the nonce and a Chainlink external adapter recovers the pubKey from the signature and verifies it
- If the validation passes the SkillWallet is marked as Active and from now on can be used for signing further transactions.
- At this point, new users will receive their personal NFT ID – and own, de-facto, their universal, non-transferable, self-sovereign identity on the Blockchain.

# Contracts

### 1. SkillWallet 
Location: `/contracts/main/SkillWallet.sol`
Addresses:
- Matic mainnet: `0x14DEF8Be678589dd1445A46Fc5bE925d479694B9`
- Matic testnet (Mumbai): `0xB0aD4014Ee360A2c7c668F2883ed73ae6780c817`
- RSK testnet: `0x5dDA86D336Aad78eDb8025902ab3DF8517df446E`

Smart contract used for SkillWallet management. Inherits from the ERC721 standard. Each SkillWallet is an NT-NFT (Non-transferable non-fungible token)
Uses Chainlink VRF (inherits from VRFConsumerBase) for creating random hash, used for QR code verification.
