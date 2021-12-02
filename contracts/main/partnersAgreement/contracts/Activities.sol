//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Activities is ERC721 {
    using Counters for Counters.Counter;

    event ActivityCreated(uint256 _id, Type _type, string _uri);
    event ActivityFinalized(uint256 _id, Type _type, string _uri);
    event TaskTaken(uint256 _activityId, uint256 _taskId, address _taker);
    event TaskFinalized(uint256 _activityId, uint256 _taskId, address _taker);

    enum Type {
        None,
        CoreTeamTask,
        DiscordPoll,
        CommunityCall
    }

    enum TaskStatus {
        Created,
        Taken,
        Finished
    }

    struct Task {
        uint256 activityId;
        uint256 createdOn;
        TaskStatus status;
        address creator;
        address taker;
    }

    address public partnersAgreement;
    address public botAddress;
    mapping (uint256 => Type) public idTypes;
    Counters.Counter private idCounter;
    mapping (uint256 => uint256) public activityToTask;
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
        require(idTypes[_id] != Type.None && idTypes[_id] != Type.CoreTeamTask, "activity doesnt exist");
        require(!isFinalized[_id], "already finalized");

        if(bytes(_uri).length > 0) {
            _setTokenURI(_id, _uri);
        }

        isFinalized[_id] = true;

        emit ActivityFinalized(_id, idTypes[_id], _uri);
    }

    function _addActivity(Type _type, string memory _uri) internal returns (uint256) {
        uint256 tokenId = idCounter.current();

        _safeMint(partnersAgreement, tokenId);
        _setTokenURI(tokenId, _uri);
        idTypes[tokenId] = _type;
        idCounter.increment();

        emit ActivityCreated(tokenId, _type, _uri);

        return tokenId;
    }

    //core team member task functions

    function createTask(string memory _uri, address _creator) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(bytes(_uri).length > 0, "No URI");

        uint256 activityId = _addActivity(Type.CoreTeamTask, _uri);
        uint256 taskId = tasks.length;

        tasks.push(Task(activityId, block.timestamp, TaskStatus.Created, _creator, address(0)));
        activityToTask[activityId] = taskId;     
    }

    function takeTask(uint256 _activityId, address _taker) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(idTypes[_activityId] == Type.CoreTeamTask, "Not core team task");

        uint256 taskId = activityToTask[_activityId];
        require(tasks[taskId].status == TaskStatus.Created, "wrong status");

        tasks[taskId].taker = _taker;
        tasks[taskId].status = TaskStatus.Taken;

        emit TaskTaken(_activityId, taskId, _taker);
    }

    function finilizeTask(uint256 _activityId, address _taker) public {
        require(msg.sender == partnersAgreement, "Not PA");
        require(idTypes[_activityId] == Type.CoreTeamTask, "Not core team task");

        uint256 taskId = activityToTask[_activityId];
        require(tasks[taskId].status == TaskStatus.Taken, "wrong status");
        require(tasks[taskId].taker == _taker, "wrong taker");

        tasks[taskId].status = TaskStatus.Finished;
        isFinalized[_activityId] = true;

        emit TaskFinalized(_activityId, taskId, _taker);
    }

    //getters

    function getActivitiesByType(uint256 _type) public view returns (uint256[] memory) {
        require(_type <= 3, "Wrong type");

        uint256[] memory ids = new uint256[](idCounter.current());
        uint256 num = 0;

        for (uint256 i = 0; i < idCounter.current(); i++) {
            if (idTypes[i] == Type(_type)) {
                ids[num] = i;
                num++;
            }
        }

        uint256[] memory idsTrimmed = new uint256[](num);

        for (uint256 i = 0; i < num; i++) {
            idsTrimmed[i] = ids[i];
        }

        return idsTrimmed;
    }

    function getTaskByActivityId(uint256 _activityId) public view returns (Task memory) {
        require(idTypes[_activityId] == Type.CoreTeamTask, "Not core team task");

        return tasks[activityToTask[_activityId]];
    }
}