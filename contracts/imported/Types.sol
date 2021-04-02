library Types {
    struct SkillSet {
        Skill skill1;
        Skill skill2;
        Skill skill3;
    }
    struct Skill {
        uint64 displayStringId;
        uint8 posValue;
        uint8 level;
    }
}