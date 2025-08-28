// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ILuckySpin
 * @dev Interface for the LuckySpin facet (Signature-based with Nonce)
 */
interface ILuckySpin {

    event SegmentRemoved(uint8 indexed segmentId);
    event SegmentAdded(uint8 indexed segmentId, uint256 rewardAmount, address tokenAddress);
    event SegmentUpdated(uint8 indexed segmentId, uint256 rewardAmount, address tokenAddress);
    /**
     * @dev Emitted when a user successfully spins using a valid signature
     */
    event SpinExecuted(address indexed player, uint8 indexed segmentId, uint256 amount, address tokenAddress);
    
    /**
     * @dev Emitted when the contract is paused or unpaused
     */
    event PausedStateChanged(bool isPaused);
    
    /**
     * @dev Emitted when the trusted signer address is updated
     */
    event TrustedSignerChanged(address indexed newSigner);

    /**
     * @dev Emitted when spin fee is updated (if applicable)
     */
    event SpinFeeUpdated(uint256 newFee);

    /**
     * @dev Emitted when a nonce is used by a player during spinWithSignature
     */
    event NonceUsed(address indexed player, uint256 nonce);

    /**
     * @dev Initialize the LuckySpin facet
     * @param trustedSigner_ The initial address authorized to sign spin requests
     * @param initialSpinFee_ The initial spin fee (if configurable)
     */
    function initialize(address trustedSigner_, uint256 initialSpinFee_) external;
    
    /**
     * @dev Set the paused state (only owner)
     * @param paused Whether the contract should be paused
     */
    function setLuckySpinPaused(bool paused) external;
    
    /**
     * @dev Set the trusted signer address (only owner)
     * @param newSigner The address of the new backend signer
     */
    function setTrustedSigner(address newSigner) external;
    
    /**
     * @dev Set the spin fee (only owner, if applicable)
     * @param fee The new spin fee in wei
     */
    function setSpinFee(uint256 fee) external;
    
    /**
     * @dev Allows a user to execute a spin using a signature provided by the backend.
     * The signature authorizes a specific reward (segmentId) and uses a nonce.
     * @param segmentId The segment ID determining the reward, as signed by the backend.
     * @param signature The ECDSA signature from the trusted backend signer.
     */
    function spinWithSignature(uint8 segmentId, bytes calldata signature) external payable;
    
    /**
     * @dev Returns the current nonce for a given user.
     * @param user The address of the user whose nonce to check.
     * @return The current nonce.
     */
    function getCurrentNonce(address user) external view returns (uint256);
    
    /**
     * @dev Returns the current trusted signer address
     */
    function getTrustedSigner() external view returns (address);
    
    /**
     * @dev Returns the current spin fee (if applicable)
     */
    function getSpinFee() external view returns (uint256);
} 