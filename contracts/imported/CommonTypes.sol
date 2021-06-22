//SPDX-License-Identifier: MIT
pragma solidity ^0.6.10;

library Types {
    struct SkillSet {
        Skill skill1;
        Skill skill2;
        Skill skill3;
    }
    struct Skill {
        uint64 displayStringId;
        uint8 level;
    }
    enum Template {
        OpenSource, 
        Art, 
        Local,
        Other
    }

    struct LatestSkills {
        uint8 posValue;
        uint256 categoryID;
    }

    enum Action {
        Activate,
        Login, 
        CreateGig,
        TakeGig,
        SubmitGig,
        CompleteGig
    }

    struct SWValidationRequest {
        address caller;
        Types.Action action;
        Types.Params params;
    }

    struct Params {
        string[] stringParams;
        uint[] intParams;
        address[] addressParams;
    }

}