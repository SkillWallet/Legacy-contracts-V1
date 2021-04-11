# Skill Wallet Contracts
Skill Wallet Contracts


### 1. SkillWallet 
Location: `/contracts/main/SkillWallet.sol`
Addresses:
- Matic mainnet: `0x14DEF8Be678589dd1445A46Fc5bE925d479694B9`
- Matic testnet (Mumbai): `0xB0aD4014Ee360A2c7c668F2883ed73ae6780c817`
- RSK testnet: `0x5dDA86D336Aad78eDb8025902ab3DF8517df446E`

Smart contract used for SkillWallet management. Inherits from the ERC721 standard. Each SkillWallet is an NT-NFT (Non-transferable non-fungible token)
Uses Chainlink VRF (inherits from VRFConsumerBase) for creating random hash, used for QR code verification.

### 2. CommunitiesRegistry.sol 
Location: `/contracts/imported/CommunitiesRegistry.sol`
Addresses:
- Matic mainnet: `0xB4Dcc7cE6C7e8E5595fBC708b09123A86360e3e2`
- Matic testnet (Mumbai): `0xAED585cE5F23D34784De65534500d0a0CD119ef3`
- RSK testnet: `0xd6b562Cb49B8a9DA7A3C4d73d96Bb5eA19F51299`

Smart contract used for Community management and community proxy functions. Inherits from ChainlinkClient, and uses Chainlink for offchain credits computation based on
the user's skills. Current implementation uses a public core adapter (HttpGet). External adapter is in progress.


### 3. Community.sol
Location: `/contracts/imported/Community.sol`
Addresses:
- Matic mainnet: `0x1cfe58e4319518400Dc83043C2Edd53ACEE9C07b`
- Matic testnet (Mumbai): `0x280971a2bd5D2506d11AC8ce2d3FCaB58A267AE4`

Smart contract for managing Communities and the activities in the communities themselves. 
It is implemented as ERC1155 (Inherits from ERC1155 with small modifications) and issues two types of tokens: DitoCredits and Community tokens. 
