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


## Contracts 

When you sign the Partners Agreement from https://playground.skillwallet.id there are two contracts deployed under the hood - PartnersAgreement.sol and Community.sol 
The Community.sol is managing the membership in the community. 
PartnersAgreement.sol is managing activities - tasks, polls, and community calls.

In order to use them within your contract after you sign the Partners Agreement, you can use partnersAgreementAddress, that you get after deploying it. 
From Partners Agreement, you can use `communityAddress()` to fetch the community address. 

In order to fetch SkillWallet data - such as whether is activated or not, roles, community history - you can use the ISkillWallet interface. 

Deployed on Mumbai `0xfb19708dEc0c84b739F98D9AAAE719D236Af3B32`!

Tasks and Events are represented by Activities.sol, that is deployed when creating the first one. You can fetch the address of the Activities, by calling `getActivitiesAddress()`.

After finalizing a task/event, the SkillWallet holder's interaction index is increased. In order to access Interactions contract - call `getInteractionsAddr()` from Activities contract.

## Imports

1. SkillWallet
`import "skill-wallet/contracts/main/ISkillWallet.sol";`
`import "skill-wallet/contracts/main/utils/RoleUtils.sol";`

2. Community 
`import "skill-wallet/contracts/main/community/ICommunity.sol;"`

3. PartnersAgreement
`import "skill-wallet/contracts/main/partnersAgreement/interfaces/IPartnersAgreement.sol;"`

4. Activities & Interactions
`import "skill-wallet/contracts/main/partnersAgreement/interfaces/IActivities.sol";`
`import "skill-wallet/contracts/main/partnersAgreement/contracts/Interaction.sol";`

## Flow

1. After creating and activating the skillWallet through the SW app & DiTo Web, the app can trigger the off-chain signature mechanism
2. The user scans a QR code with encoded nonce & action and the app calls the validate function from the SkillWallet.sol contract
3. The Validate function triggers the external adapter and verifies the signature. 
4. The chainlink callback calls the coresponding SWActionExecutor depending on the action 
4. The contract which is executing the request should implement ISWActionExecutor (The actions are predefined by the SkillWallet contract)
5. By implementing the interface, the contract will be able to gain the benefits of fast and secure, UX friendly signature mechanism.
<br/><br/>
The SkillWallet.sol contract can be used for getting the SW data such as check if it's activated, skillSet, current and history of communities.
