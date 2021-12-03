//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "../../../imported/CommonTypes.sol";

interface IPartnersAgreement {
    function activatePA() external;

    function addURL(string memory _url) external;

    function removeURL(string memory _url) external;

    function getURLs() external view returns (string[] memory);

    function isURLListed(string memory _url) external view returns (bool);

    function getInteractionNFTContractAddress() external view returns (address);

    function getAllMembers() external view returns (address[] memory);

    function transferInteractionNFTs(address user, uint256 amountOfInteractions)
        external;

    function getInteractionNFT(address user) external view returns (uint256);

    function addNewContractAddressToAgreement(address contractAddress) external;

    function getImportedAddresses() external view returns (address[] memory);

    function membershipAddress() external view returns (address);

    function rolesCount() external view returns (uint256);

    function communityAddress() external view returns (address);

    function isActive() external view returns (bool);

    function isCoreTeamMember(address member) external view returns (bool);

    function coreTeamMembersCount() external view returns (uint256);

    function addNewCoreTeamMembers(address member) external;

    function getCoreTeamMembers() external view returns (address[] memory);

    function getAgreementData()
        external
        view
        returns (Types.PartnersAgreementData memory data);
}
