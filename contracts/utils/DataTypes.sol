//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

/// @author DistributedTown team
/// @title Library containing the DataTypes used by the DistributedTown projects
library DataTypes {

    struct SkillWallet {
        address[] tokens;
        bytes32 skillsHash;
    }
}
