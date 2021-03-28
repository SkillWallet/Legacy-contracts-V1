//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @author DistributedTown team
/// @title Library containing the DataTypes used by the DistributedTown projects
library Types {
    struct Member {
        Skill skill1;
        Skill skill2;
        Skill skill3;
    }
    struct Skill {
        uint8 value;
        uint8 level;
    }
}