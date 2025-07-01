// Filename: contracts/UserMechanics/NovaKYCVerifier.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaKYCVerifier is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => bool) public isVerified;
    event UserVerificationSet(address indexed user, bool status);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function setVerificationStatus(address user, bool status) external onlyOwner {
        isVerified[user] = status;
        emit UserVerificationSet(user, status);
    }
}