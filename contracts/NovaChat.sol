// Filename: contracts/AppIntegrations/NovaChat.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaChat is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    enum MilestoneType { Proposal, FinalVote, ConflictResolution }
    struct Milestone { MilestoneType milestoneType; string contentHash; uint256 timestamp; address author; }
    mapping(uint256 => Milestone) public milestones;
    uint256 private _milestoneCount;
    event MilestoneLogged(uint256 indexed milestoneId, MilestoneType milestoneType);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function getMilestoneCount() external view returns (uint256) { return _milestoneCount; }
    function logMilestone(MilestoneType _type, string calldata _contentHash) external onlyOwner {
        uint256 newId = _milestoneCount++;
        milestones[newId] = Milestone(_type, _contentHash, block.timestamp, msg.sender);
        emit MilestoneLogged(newId, _type);
    }
}