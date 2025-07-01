// Filename: contracts/AppIntegrations/NovaPolicyRules.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaPolicyRules is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(bytes32 => uint256) public numericRules;
    event RuleUpdated(bytes32 indexed key, uint256 newValue);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function setRule(bytes32 key, uint256 value) external onlyOwner {
        numericRules[key] = value;
        emit RuleUpdated(key, value);
    }
}