// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibShop {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.standard.game.storage");
    
    struct Item {
        uint256 limitTimeBuy;
        uint256 maxLevel;
        uint256 price;
        uint256 expiry;
        bool active;
    }

    struct UserItem {
        uint256 nextTimeBuyable;
        uint256 level;
        uint256 expiry;
    }
    
    struct ShopStorage {
        Item[] items;
        mapping(address => mapping(uint256 => UserItem)) userItems;
        bool paused;
    }

    function shopStorage() internal pure returns (ShopStorage storage ss) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }
} 