// Filename: contracts/UserMechanics/NovaProfiles.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaProfiles is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct Profile { string username; string contentHash; uint256 creationDate; }
    mapping(address => Profile) public profiles;
    mapping(bytes32 => address) public usernameOwner;
    event ProfileCreated(address indexed user, string username);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function createProfile(string calldata _username, string calldata _contentHash) external {
        require(profiles[msg.sender].creationDate == 0, "Profile: Exists.");
        bytes32 usernameHash = keccak256(abi.encodePacked(_username));
        require(usernameOwner[usernameHash] == address(0), "Profile: Taken.");
        profiles[msg.sender] = Profile(_username, _contentHash, block.timestamp);
        usernameOwner[usernameHash] = msg.sender;
        emit ProfileCreated(msg.sender, _username);
    }
}