//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

interface IPartnersAgreement {
    function activatePA() external;

    function getInteractionNFTContractAddress() external view returns (address);

    function getAllMembers() external view returns (address[] memory);

    function queryForNewInteractions(address userAddress) external;

    function transferInteractionNFTs(bytes32 _requestId, uint256 _result)
        external;

    function getInteractionNFT(address user) external view returns (uint256);

    function addNewContractAddressToAgreement(address contractAddress) external;

    function getImportedAddresses() external view returns (address[] memory);

    function membershipAddress() external view returns (address);

    function rolesCount() external view returns (uint256);
    
    function communityAddress() external view returns (address);

    function isActive() external view returns (bool);

    function getAgreementData()
        external
        view
        returns (
            uint256,
            address,
            address,
            address[] memory,
            uint256,
            address,
            address,
            uint256
        );
}
