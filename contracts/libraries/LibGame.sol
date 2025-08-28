// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibGame {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.standard.game.storage");
    struct CheckIn {
        uint256 timestamp;
        bool processed;
    }
    struct GameStorage {
        mapping(address => uint256) nextTimeReset;

        address signer;
        
        uint256 checkInFee;
        
        bool paused;

        mapping(address => bool) distributer;

        mapping(address => uint256) points;
   }
    
    function gameStorage() internal pure returns (GameStorage storage gs) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            gs.slot := position
        }
    }
} 