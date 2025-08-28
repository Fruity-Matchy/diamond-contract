// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/LibDiamond.sol";
import "../libraries/LibGame.sol";
import "../interfaces/IGame.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GameFacet is IGame, ReentrancyGuard {
    
    modifier whenNotPaused() {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        require(!gs.paused, "Game: paused");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlySigner() {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        require(msg.sender == gs.signer, "Game: only signer");
        _;
    }

    modifier onlyDistributer() {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        require(gs.distributer[msg.sender], "Game: only distributer");
        _;
    }

    function initialize(address _signer) external override {
        LibDiamond.enforceIsContractOwner();
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        gs.signer = _signer;
        gs.checkInFee = 1e14;
        gs.paused = false;
    }

    function setPaused(bool _paused) external override onlyOwner {
        LibDiamond.enforceIsContractOwner();
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        gs.paused = _paused;
        emit PausedStateChanged(_paused);
    }

    function savePoint(uint256 points) payable external {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        gs.points[msg.sender] += points;
        emit PointsUpdated(msg.sender, gs.points[msg.sender]);
    }

    function setDistributer(address _distributer, bool _isDistributer) external onlyOwner {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        gs.distributer[_distributer] = _isDistributer;
    }
    
    function setSigner(address _signer) external override onlyOwner {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        address oldSigner = gs.signer;
        gs.signer = _signer;
        emit SignerUpdated(oldSigner, _signer);
    }
    
    function setCheckInFee(uint256 _fee) external override onlyOwner {
        LibDiamond.enforceIsContractOwner();
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        gs.checkInFee = _fee;
        emit CheckInFeeUpdated(_fee);
    }
    
    function checkIn() external payable override whenNotPaused {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        require(msg.value >= gs.checkInFee, "Game: incorrect fee");
        
        require(block.timestamp >= gs.nextTimeReset[msg.sender], "Game: can only check in once per day");
        
        uint256 daysSinceEpoch = block.timestamp / 86400;
        uint256 startOfDay = daysSinceEpoch * 86400;
        gs.nextTimeReset[msg.sender] = startOfDay + 1 days;
        
        emit CheckIn(msg.sender);
    }
    
    function distributeRewards(address player, uint256 amount) external override onlyDistributer nonReentrant {
        require(address(this).balance >= amount, "Game: insufficient balance");
        
        // Transfer the reward to the player
        (bool success, ) = player.call{value: amount}("");
        require(success, "Game: reward transfer failed");
        
        emit RewardsDistributed(player, amount);
    }

    function getNextCheckInTime(address player) external view override returns (uint256) {
        LibGame.GameStorage storage gs = LibGame.gameStorage();
        return gs.nextTimeReset[player];
    }

    receive() external payable {}
    function lootBox() external payable {
        emit LootBoxOpened(msg.sender, block.timestamp);
    }
    
    
} 