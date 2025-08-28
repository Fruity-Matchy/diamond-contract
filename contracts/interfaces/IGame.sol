// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title IGame
 * @dev Interface for the Game facet
 */
interface IGame {

    event LootBoxOpened(address indexed user, uint256 timestamp);
    
    event PointsUpdated(address indexed player, uint256 points);
    
    /**
     * @dev Emitted when a user checks in
     */
    event CheckIn(address indexed player);
    
    /**
     * @dev Emitted when rewards are distributed to a player
     */
    event RewardsDistributed(address indexed player, uint256 amount);
    
    /**
     * @dev Emitted when the contract is paused or unpaused
     */
    event PausedStateChanged(bool isPaused);
    
    /**
     * @dev Emitted when the signer is updated
     */
    event SignerUpdated(address indexed previousSigner, address indexed newSigner);
    
    /**
     * @dev Emitted when check-in fee is updated
     */
    event CheckInFeeUpdated(uint256 newFee);

    /**
     * @dev Initialize the Game facet
     * @param signer The address of the signer
     */
    function initialize(address signer) external;
    
    /**
     * @dev Set the paused state (only owner)
     * @param paused Whether the contract should be paused
     */
    function setPaused(bool paused) external;
    
    /**
     * @dev Set the signer address (only owner)
     * @param signer The address of the new signer
     */
    function setSigner(address signer) external;
    
    /**
     * @dev Set the check-in fee (only owner)
     * @param fee The new check-in fee in wei
     */
    function setCheckInFee(uint256 fee) external;
    
    /**
     * @dev User checks in by paying the fee
     * @notice Resets lives to 10 and can only be used once per day
     */
    function checkIn() external payable;
    
    /**
     * @dev Distribute rewards to a player (only signer)
     * @param player The address of the player to reward
     * @param amount The amount of native tokens to distribute
     */
    function distributeRewards(address player, uint256 amount) external;

    /**
     * @dev Get the next check-in time for a player
     * @param player The address of the player to check
     * @return The next check-in time in seconds
     */
    function getNextCheckInTime(address player) external view returns (uint256);
} 