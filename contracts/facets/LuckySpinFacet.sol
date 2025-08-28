// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/LibDiamond.sol";
import "../libraries/LibLuckySpin.sol";
import "../interfaces/ILuckySpin.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract LuckySpinFacet is ILuckySpin, ReentrancyGuard {
    using ECDSA for bytes32;
    
    // Commit expiration time (24 hours in seconds)
    uint256 constant COMMIT_EXPIRATION = 86400;
    
    modifier whenNotPaused() {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        require(!ls.paused, "LS: paused");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
    
    function initialize(address trustedSigner_, uint256 initialSpinFee_) external override onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        
        ls.trustedSigner = trustedSigner_;
        ls.spinFee = initialSpinFee_; // Set initial fee (could be 0)
        ls.paused = false;
    }

    function addSegment(uint256 rewardAmount, address tokenAddress) external onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        ls.segments.push(LibLuckySpin.Segment(tokenAddress, rewardAmount));
        emit SegmentAdded(uint8(ls.segments.length - 1), rewardAmount, tokenAddress);
    }

    function removeSegment(uint8 segmentId) external onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        require(segmentId < ls.segments.length, "LS: invalid segment");
        ls.segments[segmentId] = ls.segments[ls.segments.length - 1];
        ls.segments.pop();
        emit SegmentRemoved(segmentId);
    }

    function updateSegment(uint8 segmentId, uint256 rewardAmount, address tokenAddress) external onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        require(segmentId < ls.segments.length, "LS: invalid segment");
        ls.segments[segmentId].tokenAddress = tokenAddress;
        ls.segments[segmentId].amount = rewardAmount;
        emit SegmentUpdated(segmentId, rewardAmount, tokenAddress);
    }
    
    function setLuckySpinPaused(bool _paused) external override onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        ls.paused = _paused;
        emit PausedStateChanged(_paused);
    }
    
    function setTrustedSigner(address newSigner) external override onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        require(newSigner != address(0), "LS: Invalid signer address");
        ls.trustedSigner = newSigner;
        emit TrustedSignerChanged(newSigner);
    }
    
    function setSpinFee(uint256 _fee) external override onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        ls.spinFee = _fee;
        emit SpinFeeUpdated(_fee);
    }
    
    function getTrustedSigner() external view override returns (address) {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        return ls.trustedSigner;
    }
    
    /**
     * @notice Returns the current spin fee
     * @return The spin fee in wei
     */
    function getSpinFee() external view override returns (uint256) {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        return ls.spinFee;
    }
    
    function getCurrentNonce(address user) external view override returns (uint256) {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        return ls.userNonces[user]; // Return nonce for the specified user
    }

    function setLimitTime(uint256 _limitTime) external onlyOwner {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        ls.limitTime = _limitTime;
    }

    function getNextTimeBuyable(address user) external view returns (uint256) {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        return ls.nextTimeBuyable[user];
    }
    
    /**
     * @inheritdoc ILuckySpin
     */
    function spinWithSignature(
        uint8 segmentId,
        bytes calldata signature
    ) external payable override whenNotPaused nonReentrant {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        
        // Check spin fee (if applicable)
        if (ls.spinFee > 0) {
            require(msg.value >= ls.spinFee, "LS: insufficient fee");
        }

        if(ls.limitTime > 0) {
            require(ls.nextTimeBuyable[msg.sender] < block.timestamp, "LS: Spin not available");
            ls.nextTimeBuyable[msg.sender] = block.timestamp + ls.limitTime;
        }

        // Get user's current nonce
        uint256 currentNonce = ls.userNonces[msg.sender];

        // Verify signature including the nonce
        bytes32 messageHash = _hashSpinRequest(msg.sender, segmentId, currentNonce);
        address signer = messageHash.recover(signature);

        require(signer == ls.trustedSigner, "LS: Invalid signer");
        
        // Increment nonce *after* successful verification to prevent reuse
        ls.userNonces[msg.sender] = currentNonce + 1;
        emit NonceUsed(msg.sender, currentNonce);
        
        // Check segment validity (ensure it exists)
        require(segmentId < ls.segments.length, "LS: invalid segment");
        LibLuckySpin.Segment storage segment = ls.segments[segmentId];
        
        // Grant reward (if ERC20)
        if (segment.tokenAddress != address(0) && segment.amount > 0) {
            IERC20(segment.tokenAddress).transfer(msg.sender, segment.amount);
        } else if(segment.tokenAddress == address(1) && segment.amount > 0) {
            (bool success, ) = msg.sender.call{value: segment.amount}("");
            require(success, "LS: Transfer failed");
        }

        // Refund any excess fee paid
        if (msg.value > ls.spinFee) {
            payable(msg.sender).transfer(msg.value - ls.spinFee);
        }

        emit SpinExecuted(msg.sender, segmentId, segment.amount, segment.tokenAddress);
    }

    /**
     * @dev Internal function to create the hash for signing.
     * Includes player, segment, *nonce*, contract address, and chain ID.
     */
    function _hashSpinRequest(
        address player,
        uint8 segmentId,
        uint256 nonce
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            player, 
            segmentId, 
            nonce
        ));
    }
    
    // View function to get segment details
    function getSegmentDetails(uint8 segmentId) external view returns (
        address tokenAddress,
        uint256 amount
    ) {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        
        require(segmentId < ls.segments.length, "LS: invalid segment");
        
        LibLuckySpin.Segment memory segment = ls.segments[segmentId];
        
        return (
            segment.tokenAddress,
            segment.amount
        );
    }
    
    // View function to get the number of segments
    function getSegmentsCount() external view returns (uint256) {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        return ls.segments.length;
    }
    
    receive() external payable {}

    function spin() external {
        LibLuckySpin.LuckySpinStorage storage ls = LibLuckySpin.luckySpinStorage();
        uint8 randomNumber = uint8(random(ls.segments.length));
        emit SpinExecuted(msg.sender, randomNumber, ls.segments[randomNumber].amount, ls.segments[randomNumber].tokenAddress);
    }

    function random(uint256 max) public view returns (uint256) {
        require(max > 0);

        return uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1), 
                    block.prevrandao,           
                    msg.sender,                  
                    block.timestamp               // adds more variation
                )
            )
        ) % max;
    }
} 