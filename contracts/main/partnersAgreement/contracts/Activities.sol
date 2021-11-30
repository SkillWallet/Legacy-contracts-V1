//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Activities is ERC721 {
    using Counters for Counters.Counter;

    enum Type {
        None,
        CoreTeamTask,
        DiscordPoll,
        CommunityCall
    }

    struct Task {
        uint256 activityId;
        uint256 createdOn;
        uint256 status;
        string description;
        address creator;
        address taker;
    }

    address public partnersAgreement;
    address public botAddress;
    mapping (uint256 => Type) public idTypes;
    Counters.Counter private idCounter;
    mapping (uint256 => uint256) activityToTask;
    Task[] public tasks;
    mapping (uint256 => bool) public isFinalized;

    constructor(address _pa, address _bot) public ERC721("Activities", "ACT") {
        require(_pa != address(0), "no PA address");
        require(_bot != address(0), "no bot address");

        partnersAgreement = _pa;
        botAddress = _bot;
    }

    function createActivity(uint256 _type, string memory _uri) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(Type(_type) != Type.None, "No type");
        require(Type(_type) != Type.CoreTeamTask, "Use createTask for tasks");
        require(bytes(_uri).length > 0, "No URI");

        _addActivity(Type(_type), _uri);
    }

    function finalizeActivity(uint256 _id, string memory _uri) public {
        require(msg.sender == botAddress, "noy bot");
        require(idTypes[_id] != Type.None && idTypes[_id] != Type.CoreTeamTask, "activity doesn't exist");
        require(!isFinalized[_id], "already finalized");

        if(bytes(_uri).length > 0) {
            _setTokenURI(_id, _uri);
        }

        isFinalized[_id] = true;
    }

    function _addActivity(Type _type, string memory _uri) internal returns (uint256) {
        uint256 tokenId = idCounter.current();

        _safeMint(partnersAgreement, tokenId);
        _setTokenURI(tokenId, _uri);
        idTypes[tokenId] = _type;
        idCounter.increment();

        return tokenId;
    }

    //core team member task functions

    function createTask(string memory _uri, string memory _description, address _creator) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(bytes(_uri).length > 0, "No URI");

        uint256 activityId = _addActivity(Type.CoreTeamTask, _uri);
        uint256 taskId = tasks.length;

        tasks.push(Task(activityId, block.timestamp, 0, _description, _creator, address(0)));
        activityToTask[activityId] = taskId;     
    }

    function takeTask(uint256 _activityId, address _taker) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(idTypes[_activityId] == Type.CoreTeamTask, "Not core team task");

        uint256 taskId = activityToTask[_activityId];
        require(tasks[taskId].status == 0, "wrong status");

        tasks[taskId].taker = _taker;
        tasks[taskId].status = 1;
    }

    function finilizeTask(uint256 _activityId, address _taker) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(idTypes[_activityId] == Type.CoreTeamTask, "Not core team task");

        uint256 taskId = activityToTask[_activityId];
        require(tasks[taskId].status == 1, "wrong status");
        require(tasks[taskId].taker == _taker, "wrong taker");

        tasks[taskId].status = 2;
        isFinalized[_activityId] = true;
    }
}