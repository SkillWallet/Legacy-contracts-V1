//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;
import "../../../imported/CommonTypes.sol";

interface IPartnersAgreement {
    function addURL(string memory _url) external;

    function removeURL(string memory _url) external;

    function getURLs() external view returns (string[] memory);

    function isURLListed(string memory _url) external view returns (bool);

    function getActivitiesAddress() external view returns (address);

    function getAllMembers() external view returns (address[] memory);

    function addNewContractAddressToAgreement(address contractAddress) external;

    function getImportedAddresses() external view returns (address[] memory);

    function rolesCount() external view returns (uint256);

    function communityAddress() external view returns (address);

    function isActive() external view returns (bool);

    function commitmentLevel() external view returns (uint256);

    function getAgreementData()
        external
        view
        returns (Types.PartnersAgreementData memory data);

    function getSkillWalletAddress() external view returns (address);
}
