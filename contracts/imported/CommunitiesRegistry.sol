//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;
import "./Community.sol";
import "./Membership.sol";

/**
 * @title DistributedTown CommunitiesRegistry
 *
 * @dev Implementation of the CommunitiesRegistry contract, which is a Factory and Registry of Communities
 * @author DistributedTown
 */
contract CommunitiesRegistry {
    event CommunityCreated(address indexed creator, address indexed community, address indexed membership, string name);

    mapping(address => bool) public isCommunity;
    address[] public communityAddresses;
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
    ) external returns (address _communityAddress) {
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

        isCommunity[newCommunityAddress] = true;
        communityAddresses.push(newCommunityAddress);
        numOfCommunities = numOfCommunities + 1;

        emit CommunityCreated(msg.sender, newCommunityAddress, address(community.getMembership()), community.name());

        return newCommunityAddress;
    }

    function joinNewMember(
        address community,
        address userAddress,
        uint64 displayStringId1,
        uint8 level1,
        uint64 displayStringId2,
        uint8 level2,
        uint64 displayStringId3,
        uint8 level3,
        string calldata uri,
        uint256 credits
    ) external {
        require(isCommunity[community], "Invalid community address!");

        Community communityContr = Community(community);
        communityContr.joinNewMember(userAddress, displayStringId1, level1, displayStringId2, level2, displayStringId3, level3, uri, credits);
    }

    function joinExistingSW(
        address community,
        uint256 skillWalletTokenId,
        uint256 credits
    ) external {
        require(isCommunity[community], "Invalid community address!");

        Community communityContr = Community(community);
        communityContr.join(skillWalletTokenId, credits);
    }

    function getCommunities() public view returns(address[] memory) {
        return communityAddresses;
    }
}
