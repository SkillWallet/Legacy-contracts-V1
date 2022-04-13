//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./Interaction.sol";
import "../interfaces/IActivities.sol";
import "../../SkillWallet.sol";
import "../../community/ICommunity.sol";

contract Activities is IActivities, ERC721, IERC721Receiver {
    using Counters for Counters.Counter;

    event ActivityCreated(uint256 _id, Type _type, string _uri);
    event ActivityFinalized(uint256 _id, Type _type, string _uri);
    event TaskTaken(uint256 _activityId, uint256 _taskId, address _taker);
    event TaskSubmitted(uint256 _activityId, uint256 _taskId);
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
        Submitted,
        Finished
    }

    struct Task {
        uint256 activityId;
        uint256 createdOn;
        TaskStatus status;
        address creator;
        address taker;
        string submitionUrl;
    }

    modifier onlyCoreTeam() {
        require(
            ICommunity(community).isCoreTeamMember(msg.sender),
            "The signer is not whitelisted as core team member!"
        );
        _;
    }

    address public community;
    mapping(uint256 => Type) public idTypes;
    Counters.Counter private idCounter;
    mapping(uint256 => uint256) public activityToTask;
    Task[] public tasks;
    mapping(uint256 => bool) public isFinalized;
    address public discordBotAddress;
    Interaction interactions;

    constructor(address _community, address _discordBotAddress)
        public
        ERC721("Tsk", "TSK")
    {
        require(_community != address(0), "no community address");

        community = _community;
        discordBotAddress = _discordBotAddress;
        interactions = new Interaction();
    }

    function createActivity(uint256 _type, string memory _uri)
        public
        override
        onlyCoreTeam
    {
        require(Type(_type) != Type.None, "No type");
        require(Type(_type) != Type.CoreTeamTask, "Use createTask for tasks");
        require(bytes(_uri).length > 0, "No URI");

        _addActivity(Type(_type), _uri);
    }

    function setDiscordBotAddress(
        address _discordBotAddress
    ) public onlyCoreTeam {
        discordBotAddress = _discordBotAddress;
    }

    function finalizeActivity(
        uint256 _id,
        string memory _uri,
        address[] calldata members
    ) public override {
        require(
            msg.sender == discordBotAddress,
            "Only Discord Bot Can call this."
        );
        require(
            idTypes[_id] != Type.None && idTypes[_id] != Type.CoreTeamTask,
            "activity doesnt exist"
        );
        require(!isFinalized[_id], "already finalized");

        if (bytes(_uri).length > 0) {
            _setTokenURI(_id, _uri);
        }

        isFinalized[_id] = true;

        for (uint256 i = 0; i < members.length; i++) {
            interactions.addInteraction(_id, members[i]);
        }

        emit ActivityFinalized(_id, idTypes[_id], _uri);
    }

    function _addActivity(Type _type, string memory _uri)
        internal
        returns (uint256)
    {
        uint256 tokenId = idCounter.current();

        _safeMint(address(this), tokenId);
        _setTokenURI(tokenId, _uri);
        idTypes[tokenId] = _type;
        idCounter.increment();

        emit ActivityCreated(tokenId, _type, _uri);

        return tokenId;
    }

    //core team member task functions
    function createTask(string memory _uri) public override onlyCoreTeam {
        require(bytes(_uri).length > 0, "No URI");

        uint256 activityId = _addActivity(Type.CoreTeamTask, _uri);
        uint256 taskId = tasks.length;

        tasks.push(
            Task(
                activityId,
                block.timestamp,
                TaskStatus.Created,
                msg.sender,
                address(0),
                ""
            )
        );
        activityToTask[activityId] = taskId;
    }

    function takeTask(uint256 _activityId) public override {
        require(
            idTypes[_activityId] == Type.CoreTeamTask,
            "Not core team task"
        );

        uint256 taskId = activityToTask[_activityId];
        require(tasks[taskId].status == TaskStatus.Created, "wrong status");
        require(
            tasks[taskId].creator != msg.sender,
            "Creator can't take the task."
        );

        tasks[taskId].taker = msg.sender;
        tasks[taskId].status = TaskStatus.Taken;

        emit TaskTaken(_activityId, taskId, msg.sender);
    }


    function submitTask(uint256 _activityId, string calldata _submitionUrl) public override {
        require(
            idTypes[_activityId] == Type.CoreTeamTask,
            "Not core team task"
        );

        uint256 taskId = activityToTask[_activityId];
        require(tasks[taskId].status == TaskStatus.Taken, "wrong status");
        require(
            tasks[taskId].taker == msg.sender,
            "Only taker can submit a task."
        );

        tasks[taskId].status = TaskStatus.Submitted;
        tasks[taskId].submitionUrl = _submitionUrl;

        emit TaskSubmitted(_activityId, taskId);
    }

    function finilizeTask(uint256 _activityId) public override {
        require(
            idTypes[_activityId] == Type.CoreTeamTask,
            "Not core team task"
        );

        uint256 taskId = activityToTask[_activityId];

        require(
            tasks[taskId].creator == msg.sender,
            "Only creator can finalize!"
        );
        require(tasks[taskId].status == TaskStatus.Submitted, "wrong status");

        tasks[taskId].status = TaskStatus.Finished;
        isFinalized[_activityId] = true;

        interactions.addInteraction(_activityId, tasks[taskId].taker);

        emit TaskFinalized(_activityId, taskId, tasks[taskId].taker);
    }

    //getters
    function getActivitiesByType(uint256 _type)
        public
        view
        override
        returns (uint256[] memory)
    {
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

    function getTaskByActivityId(uint256 _activityId)
        public
        view
        returns (Task memory)
    {
        require(
            idTypes[_activityId] == Type.CoreTeamTask,
            "Not core team task"
        );

        return tasks[activityToTask[_activityId]];
    }

    function getInteractionsAddr() public view override returns (address) {
        return address(interactions);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
