// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol"; // Optional: To restrict minting

/**
 * @title SampleToken
 * @dev A basic ERC20 token with 6 decimals, primarily for testing.
 * Mints the initial supply to the deployer.
 */
contract SampleToken is ERC20, Ownable {
    // Define the number of decimals for the token
    uint8 private constant _DECIMALS = 6;
    // Calculate the initial supply (e.g., 1,000,000 tokens)
    uint256 private constant _INITIAL_SUPPLY = 1_000_000 * (10**uint256(_DECIMALS));

    /**
     * @dev Sets the values for {name}, {symbol}, and mints initial supply.
     * The deployer automatically becomes the owner.
     */
    constructor() ERC20("Sample USDT", "sUSDT") Ownable() { // Ownable constructor takes no arguments
        _mint(msg.sender, _INITIAL_SUPPLY);
        // Ownership is implicitly set to msg.sender by Ownable's constructor
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return _DECIMALS;
    }

    // Optional: Add a public mint function restricted to the owner
    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }
} 