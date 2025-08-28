// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IShop
 * @dev Interface for the Shop facet
 */
interface IShop {
    /**
     * @dev Emitted when an item is bought
     * @param buyer The address of the buyer
     * @param itemId The ID of the bought item
     * @param itemExpiry The expiry timestamp of the item
     * @param nextTimeBuyable The next time the item can be bought
     * @param level The new level of the item for the buyer
     */
    event Bought(address indexed buyer, uint256 itemId, uint256 itemExpiry, uint256 nextTimeBuyable, uint256 level);

    /**
     * @dev Emitted when the market is paused or unpaused
     * @param isPaused Whether the market is paused
     */
    event MarketPaused(bool isPaused);
    
    /**
     * @dev Initialize the Shop facet
     */
    function initialize() external;
    
    /**
     * @dev Set the paused state (only owner)
     * @param paused Whether the contract should be paused
     */
    function setShopPaused(bool paused) external;
    
    /**
     * @dev Add a new item to the shop (only owner)
     * @param limitTimeBuy Time limit between purchases
     * @param maxLevel Maximum level for the item
     * @param price Price of the item in wei
     * @param expiry Expiry duration of the item
     * @param active Whether the item is active
     */
    function addItem(uint256 limitTimeBuy, uint256 maxLevel, uint256 price, uint256 expiry, bool active) external;
    
    /**
     * @dev Update an existing item (only owner)
     * @param itemId ID of the item to update
     * @param limitTimeBuy New time limit between purchases
     * @param maxLevel New maximum level for the item
     * @param price New price of the item in wei
     * @param expiry New expiry duration of the item
     * @param active New active status of the item
     */
    function updateItem(uint256 itemId, uint256 limitTimeBuy, uint256 maxLevel, uint256 price, uint256 expiry, bool active) external;
    
    /**
     * @dev Buy an item from the shop
     * @param itemId ID of the item to buy
     */
    function buyItem(uint256 itemId) external payable;
    
    /**
     * @dev Get user's item information
     * @param user Address of the user
     * @param itemId ID of the item
     * @return nextTimeBuyable Next time the item can be bought
     * @return level Current level of the item for the user
     */
    function getUserItem(address user, uint256 itemId) external view returns (uint256 nextTimeBuyable, uint256 level);
    
    /**
     * @dev Get item information
     * @param itemId ID of the item
     * @return limitTimeBuy Time limit between purchases
     * @return maxLevel Maximum level for the item
     * @return price Price of the item in wei
     * @return expiry Expiry duration of the item
     * @return active Whether the item is active
     */
    function getItem(uint256 itemId) external view returns (uint256 limitTimeBuy, uint256 maxLevel, uint256 price, uint256 expiry, bool active);
    
    /**
     * @dev Get the total number of items in the shop
     * @return Total number of items
     */
    function getItemCount() external view returns (uint256);
} 