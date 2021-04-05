//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Community.sol";
import "./Membership.sol";

/**
 * @title DistributedTown CommunitiesRegistry
 *
 * @dev Implementation of the CommunitiesRegistry contract, which is a Factory and Registry of Communities
 * @author DistributedTown
 */
contract CommunitiesRegistry {
    event CommunityCreated(address _newCommunityAddress);

    mapping(address => bool) public communities;
    uint256 public numOfCommunities;
    address public skillWalletAddress;

    constructor(address _skillWalletAddress) public {
        skillWalletAddress = _skillWalletAddress;
    }

    /**
     * @dev Creates a community
     * @return _communityAddress the newly created Community address
     **/
    function createCommunity(
        string memory _url,
        uint256 _ownerId,
        uint256 _ownerCredits,
        string memory _name,
        Types.Template _template,
        uint8 _positionalValue1,
        uint8 _positionalValue2,
        uint8 _positionalValue3
    ) public returns (address _communityAddress) {
        Community community =
            new Community(
                _url,
                _ownerId,
                _ownerCredits,
                _name,
                _template,
                _positionalValue1,
                _positionalValue2,
                _positionalValue3,
                skillWalletAddress,
                address(this)
            );
        address newCommunityAddress = address(community);

        numOfCommunities = numOfCommunities + 1;
        communities[newCommunityAddress] = true;

        emit CommunityCreated(newCommunityAddress);

        return newCommunityAddress;
    }

    function joinNewMember(
        address community,
        Types.SkillSet calldata skillSet,
        string calldata uri,
        uint256 credits
    ) public {
        require(communities[community], "Invalid community address!");

        Community communityContr = Community(community);
        communityContr.joinNewMember(msg.sender, skillSet, uri, credits);
    }

    function joinExistingSW(
        address community,
        uint256 skillWalletTokenId,
        uint256 credits
    ) public {
        require(communities[community], "Invalid community address!");

        Community communityContr = Community(community);
        communityContr.join(skillWalletTokenId, credits);
    }
}
