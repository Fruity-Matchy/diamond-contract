// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Removed ECDSA import as it will be used in Facet directly
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibLuckySpin {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.standard.luckyspin.storage");
    
    // Define a segment structure
    struct Segment {
        address tokenAddress;
        uint256 amount;
        // Add other potential segment properties if needed, e.g., rewardType off-chain identifier
    }
    
    // Removed UserCommit struct
    
    struct LuckySpinStorage {
        address trustedSigner; // Renamed from signer for clarity
        uint256 spinFee; // Keep if fee is configurable, otherwise make constant in Facet
        bool paused;
        
        mapping(address => uint256) userNonces; // Added back for replay protection
        Segment[] segments;
        uint256 limitTime;
        mapping(address => uint256) nextTimeBuyable;
    }
    
    function luckySpinStorage() internal pure returns (LuckySpinStorage storage ls) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ls.slot := position
        }
    }
    
    // Removed computeCommitHash function
} 