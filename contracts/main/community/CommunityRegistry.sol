//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./Community.sol";

contract CommunityRegistry is Initializable {

    event CommunityCreated(address comAddr);

    //versioning
    uint256 public version;
    address skillWalletAddress; 
    address deployer;

    function initialize(
        address _skillWalletAddress
    ) public initializer {
        skillWalletAddress = _skillWalletAddress;

        version = 1;
        deployer = msg.sender;
    }

    function setVersion(uint256 _version) public {
        require(msg.sender == deployer, "Only deployer can set verison");
        version = _version;
    }

    function createCommunity(
        string calldata url,
        uint256 template,
        uint256 totalMembersAllowed,
        uint coreTeamMembersCount,
        bool isPermissioned,
        address migrateFrom
    ) public {

        require(
            migrateFrom == address(0) ||
            msg.sender == Community(migrateFrom).owner(), "Only owner!"
        );

        address communityAddress = address(new Community(
            msg.sender,
            url,
            template,
            totalMembersAllowed,
            coreTeamMembersCount,
            version,
            skillWalletAddress,
            isPermissioned,
            migrateFrom
        ));

        emit CommunityCreated(communityAddress);
    }
}