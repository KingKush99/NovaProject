// Filename: contracts/NovaStreamerPayout.sol (TEMPORARILY MODIFIED FOR COMPILATION)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// --- TEMPORARILY COMMENTED OUT IMPORT ---
// This line is causing the HH404 error because the path might be incorrect or the file is missing for your OpenZeppelin version.
// Commenting it out allows other contracts to compile and deploy.
// import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

// --- TEMPORARILY REMOVED ReentrancyGuardUpgradeable from inheritance ---
// You will restore this once NFTAuctionHouse is deployed.
contract NovaStreamerPayout is Initializable, OwnableUpgradeable, UUPSUpgradeable /*, ReentrancyGuardUpgradeable */ { 
    event PayoutsDistributed(uint256 totalAmount, uint256 recipientCount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        // --- TEMPORARILY COMMENT OUT THE ReentrancyGuard INITIALIZER ---
        // __ReentrancyGuard_init(); // Uncomment this line AFTER NFTAuctionHouse is deployed.
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    // This allows the contract to receive MATIC/POL
    receive() external payable {}

    // --- TEMPORARILY REMOVED nonReentrant modifier ---
    // You will restore this modifier once NFTAuctionHouse is deployed.
    function distributePayouts(address payable[] calldata recipients, uint256[] calldata amounts) external onlyOwner /* nonReentrant */ {
        require(recipients.length == amounts.length, "Payouts: Mismatched arrays.");
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) { 
            totalAmount += amounts[i]; 
        }
        require(address(this).balance >= totalAmount, "Payouts: Insufficient funds.");

        for (uint i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Payouts: Transfer failed.");
        }
        emit PayoutsDistributed(totalAmount, recipients.length);
    }
}