//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

library RoleUtils {
    uint256 constant role1 = 57;
    uint256 constant role2 = 29;
    uint256 constant role3 = 14;

    enum Roles {
        NONE,
        ROLE1,
        ROLE2,
        ROLE3
    }

    function getRolesCoefs(uint256 _roleNum) internal pure returns (uint256[3] memory) {
        if (_roleNum == 2) {
            return [role1, role2 + role3, 0];
        }
        if (_roleNum == 3) {
            return [role1, role2, role3];
        }

        return [uint256(0), uint256(0), uint256(0)];
    }

    function getRoleCoef(uint256 _role, uint256 _roleNum) internal pure returns (uint256) {
        if (_role == 0) return role1;
        if (_role == 21) {
            if(_roleNum == 2) return role2 + role3;
            if(_roleNum == 3) return role2;
        }
        if (_role == 2 && _roleNum == 3) return role3;

        return 0;
    }
}