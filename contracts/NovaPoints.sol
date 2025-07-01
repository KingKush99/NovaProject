// Filename: contracts/UserMechanics/NovaPoints.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaPoints is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(address => uint256) public points;
    event PointsAdjusted(address indexed user, uint256 newBalance, int256 change);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function adjustPoints(address user, int256 amount) external onlyOwner {
        uint256 currentPoints = points[user];
        if (amount > 0) {
            points[user] = currentPoints + uint256(amount);
        } else {
            uint256 deduction = uint256(-amount);
            require(currentPoints >= deduction, "Points: Insufficient balance.");
            points[user] = currentPoints - deduction;
        }
        emit PointsAdjusted(user, points[user], amount);
    }
}