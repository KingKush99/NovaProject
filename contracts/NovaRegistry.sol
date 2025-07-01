// Filename: contracts/Core/NovaRegistry.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NovaRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(bytes32 => address) private _contractAddresses;
    event ContractRegistered(bytes32 indexed key, address indexed contractAddress);
    event ContractUpdated(bytes32 indexed key, address indexed oldAddress, address indexed newAddress);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function registerContract(bytes32 key, address contractAddress) external onlyOwner {
        require(_contractAddresses[key] == address(0), "Registry: Key already registered");
        require(contractAddress != address(0), "Registry: Zero address");
        _contractAddresses[key] = contractAddress;
        emit ContractRegistered(key, contractAddress);
    }
    function updateContractAddress(bytes32 key, address newAddress) external onlyOwner {
        address oldAddress = _contractAddresses[key];
        require(oldAddress != address(0), "Registry: Key not found");
        _contractAddresses[key] = newAddress;
        emit ContractUpdated(key, oldAddress, newAddress);
    }
    function getContractAddress(bytes32 key) external view returns (address) {
        return _contractAddresses[key];
    }
}