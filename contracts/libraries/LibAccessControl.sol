// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibAccessControl {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.access.control");

    struct RoleStorage {
        mapping(bytes32 => mapping(address => bool)) roles;
    }

    function roleStorage() internal pure returns (RoleStorage storage rs) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    function hasRole(bytes32 role, address account) internal view returns (bool) {
        return roleStorage().roles[role][account];
    }

    function grantRole(bytes32 role, address account) internal {
        roleStorage().roles[role][account] = true;
    }

    function revokeRole(bytes32 role, address account) internal {
        roleStorage().roles[role][account] = false;
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, msg.sender), "AccessControl: Access denied");
        _;
    }
}
