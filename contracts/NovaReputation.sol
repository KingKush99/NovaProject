// Filename: contracts/UserMechanics/NovaReputation.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NovaReputation is Initializable, OwnableUpgradeable, UUPSUpgradeable {

    // --- State Variables ---
    mapping(address => int256) public reputationScores;
    mapping(address => bool) public reputationAdmins; // For role-based access

    // --- Events ---
    event ReputationAdjusted(address indexed user, int256 newScore, int256 change);
    event ReputationSet(address indexed user, int256 newScore);
    event AdminStatusChanged(address indexed admin, bool status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        // The contract owner is automatically an admin
        reputationAdmins[initialOwner] = true;
    }

    modifier onlyAdmin() {
        require(reputationAdmins[msg.sender], "Not a reputation admin");
        _;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- Role Management Functions (Future Upgrade) ---
    function setAdmin(address admin, bool status) external onlyOwner {
        reputationAdmins[admin] = status;
        emit AdminStatusChanged(admin, status);
    }

    // --- Core Logic ---
    // CORRECTED: Changed from 'external' to 'public'
    function adjustReputation(address user, int256 amount) public onlyAdmin {
        reputationScores[user] += amount;
        emit ReputationAdjusted(user, reputationScores[user], amount);
    }

    // --- Batch Function (Future Upgrade) ---
    function batchAdjustReputation(address[] calldata users, int256[] calldata amounts) external onlyAdmin {
        require(users.length == amounts.length, "Arrays must be same length");
        for(uint i = 0; i < users.length; i++){
            // This will now work correctly
            adjustReputation(users[i], amounts[i]);
        }
    }

    // --- Set Function (Future Upgrade) ---
    function setReputation(address user, int256 newScore) external onlyAdmin {
        reputationScores[user] = newScore;
        emit ReputationSet(user, newScore);
    }
}