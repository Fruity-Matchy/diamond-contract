// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/LibDiamond.sol";
import "../libraries/LibShop.sol";
import "../interfaces/IShop.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ShopFacet is IShop, ReentrancyGuard {
    modifier whenNotPaused() {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        require(!ss.paused, "Shop: paused");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
    
    function initialize() external override onlyOwner {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        ss.paused = false;
    }
    
    function setShopPaused(bool paused) external override onlyOwner {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        ss.paused = paused;
        emit MarketPaused(paused);
    }

    function disabledItem(uint256 itemId) external onlyOwner {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        require(itemId < ss.items.length, "Shop: item does not exist");
        ss.items[itemId].active = false;
    }
    
    function addItem(uint256 limitTimeBuy, uint256 maxLevel, uint256 price, uint256 expiry, bool active) external onlyOwner {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        ss.items.push(LibShop.Item({
            limitTimeBuy: limitTimeBuy,
            maxLevel: maxLevel,
            price: price,
            expiry: expiry,
            active: active
        }));
    }
    
    function updateItem(uint256 itemId, uint256 limitTimeBuy, uint256 maxLevel, uint256 price, uint256 expiry, bool active) external onlyOwner {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        require(itemId < ss.items.length, "Shop: item does not exist");
        
        ss.items[itemId].limitTimeBuy = limitTimeBuy;
        ss.items[itemId].maxLevel = maxLevel;
        ss.items[itemId].price = price;
        ss.items[itemId].expiry = expiry;
        ss.items[itemId].active = active;
    }
    
    function buyItem(uint256 itemId) external payable whenNotPaused nonReentrant {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        require(itemId < ss.items.length, "Shop: item does not exist");
        require(ss.items[itemId].active, "Shop: item not active");
        
        LibShop.Item storage item = ss.items[itemId];
        LibShop.UserItem storage userItem = ss.userItems[msg.sender][itemId];
        
        require(block.timestamp >= userItem.nextTimeBuyable, "Shop: cannot buy yet");
        require(userItem.level < item.maxLevel, "Shop: max level reached");
        require(msg.value >= item.price, "Shop: insufficient payment");
        
        if(item.limitTimeBuy > 0) {
            userItem.nextTimeBuyable = block.timestamp + item.limitTimeBuy;
        }
        if(item.maxLevel > 0) {
            userItem.level += 1;
        }
        
        if(item.expiry > 0) {
            userItem.expiry = block.timestamp + item.expiry;
        }
        emit Bought(msg.sender, itemId, userItem.expiry, userItem.nextTimeBuyable, userItem.level);
    }
    
    function getUserItem(address user, uint256 itemId) external view returns (uint256 nextTimeBuyable, uint256 level) {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        require(itemId < ss.items.length, "Shop: item does not exist");
        
        LibShop.UserItem storage userItem = ss.userItems[user][itemId];
        return (userItem.nextTimeBuyable, userItem.level);
    }
    
    function getItem(uint256 itemId) external view returns (uint256 limitTimeBuy, uint256 maxLevel, uint256 price, uint256 expiry, bool active) {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        require(itemId < ss.items.length, "Shop: item does not exist");
        
        LibShop.Item storage item = ss.items[itemId];
        return (
            item.limitTimeBuy,
            item.maxLevel,
            item.price,
            item.expiry,
            item.active
        );
    }
    
    function getItemCount() external view returns (uint256) {
        LibShop.ShopStorage storage ss = LibShop.shopStorage();
        return ss.items.length;
    }
    
    receive() external payable {}
} 