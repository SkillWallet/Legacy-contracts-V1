//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

// TODO: figure out rates.
// TODO: transfer tokens.
// TODO: 1 gigs instance per community
contract Gigs {
    using Counters for Counters.Counter;

    event GigCreated(address _creator, uint256 _gigId);
    event GigCompleted(address _creator, address _gigCompleter, uint256 _gigId);
    event GigTaken(address _creator, address _taker, uint256 _gigTaker);
    event GigSubmitted(address _creator, address _gigSubmitter, uint256 _gigId);
    event GigValidated(uint256 _gigId, address _creator, string _gigHash);
    enum GigStatus {Open, Taken, Submitted, Completed}

    Counters.Counter gigId;

    struct Gig {
        address owner;
        address taker;
        string gigHash;
        uint256 ditoCredits;
        GigStatus status;
        uint16 rate;
    }

    mapping(uint256 => Gig) public gigs;
    mapping(address => uint256[]) ownersToGigs;
    mapping(address => uint256[]) completedGigs;
    mapping(uint256 => bool) isValidated;


    function createGig(uint256 ditoCredits) public {
        uint256 newGigId = gigId.current();
        gigs[gigId.current()] = Gig(
            msg.sender,
            address(0),
            "",
            ditoCredits,
            GigStatus.Open,
            0
        );

        ownersToGigs[msg.sender].push(
            newGigId
        );
        isValidated[newGigId] = false;
        gigId.increment();

        emit GigCreated(msg.sender, newGigId);
    }

    function takeGig(uint256 _gigId) public {
        require(
            gigs[_gigId].status == GigStatus.Open,
            "This gig is not open for being taken."
        );
        require(isValidated[_gigId], "Gig creation not yet validated.");

        gigs[_gigId].taker = msg.sender;
        gigs[_gigId].status = GigStatus.Taken;

        isValidated[_gigId] = false;

        emit GigTaken(gigs[_gigId].owner, msg.sender, _gigId);
    }

    function submitGig(uint256 _gigId) public {
        require(
            gigs[_gigId].status == GigStatus.Taken,
            "This gig is not yet taken."
        );
        require(isValidated[_gigId], "Gig taken not yet validated.");

        gigs[_gigId].status = GigStatus.Submitted;

        isValidated[_gigId] = false;

        emit GigSubmitted(gigs[_gigId].owner, msg.sender, _gigId);
    }

    function completeGig(uint256 _gigId, uint16 rate) public {
        require(
            gigs[_gigId].status == GigStatus.Submitted,
            "This gig is not yet submitted."
        );
        require(isValidated[_gigId], "Gig submission not yet validated.");

        gigs[_gigId].status = GigStatus.Completed;
        gigs[_gigId].rate = rate;

        completedGigs[msg.sender].push(
            _gigId
        );

        isValidated[_gigId] = false;

        emit GigCompleted(gigs[_gigId].owner, msg.sender, _gigId);
    }

    function validate(uint256 _gigId, string calldata _gigHash)
        private
        returns (bool)
    {
        // Chainlink validate hash
        isValidated[_gigId] = true;
        gigs[_gigId].gigHash = _gigHash;

        emit GigValidated(_gigId, gigs[_gigId].owner, _gigHash);
    }

    function getOwnedGigs(address owner) public view returns (uint256[] memory) {
        return ownersToGigs[owner];
    }

    function getCompletedGigs(address taker) public view returns (uint256[] memory) {
        return completedGigs[taker];
    }
}
