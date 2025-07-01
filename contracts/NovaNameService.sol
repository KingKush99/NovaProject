// Filename: contracts/UserMechanics/NovaNameService.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaNameService is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(bytes32 => address) public nameToAddress;
    mapping(address => string) public addressToName;
    event NameRegistered(string name, address indexed owner);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function registerName(string calldata name) external {
        bytes32 nameHash = keccak256(abi.encodePacked(name));
        require(nameToAddress[nameHash] == address(0), "NameService: Taken.");
        require(bytes(addressToName[msg.sender]).length == 0, "NameService: Exists.");
        nameToAddress[nameHash] = msg.sender;
        addressToName[msg.sender] = name;
        emit NameRegistered(name, msg.sender);
    }
    function resolveName(string calldata name) external view returns (address) {
        return nameToAddress[keccak256(abi.encodePacked(name))];
    }
}