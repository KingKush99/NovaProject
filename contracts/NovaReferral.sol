// Filename: contracts/UserMechanics/NovaReferral.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaReferral is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => address) private _referrals;
    mapping(address => uint256) private _timesUsed;
    event ReferralSet(address indexed user, address indexed referrer);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function refer(address user) external {
        require(user != msg.sender, "Referral: Cannot refer self.");
        require(_referrals[user] == address(0), "Referral: Already referred.");
        _referrals[user] = msg.sender;
        _timesUsed[msg.sender]++;
        emit ReferralSet(user, msg.sender);
    }
    function getReferrer(address user) external view returns (address) { return _referrals[user]; }
    function getTimesUsed(address ref) external view returns (uint256) { return _timesUsed[ref]; }
}