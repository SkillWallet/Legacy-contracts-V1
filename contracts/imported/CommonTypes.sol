pragma solidity >=0.6.0 <0.8.0;

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
}