// Filename: contracts/Core/TokenVesting.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    IERC20 public token;
    address public beneficiary;
    uint256 public startTimestamp;
    uint256 public durationSeconds;
    uint256 public totalVestingAmount;
    uint256 public releasedAmount;
    event TokensReleased(address indexed beneficiary, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner, address _beneficiary, uint256 _vestingDuration, address _tokenAddress) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        require(_beneficiary != address(0), "Vesting: No beneficiary.");
        require(_vestingDuration > 0, "Vesting: No duration.");
        require(_tokenAddress != address(0), "Vesting: No token.");
        beneficiary = _beneficiary;
        durationSeconds = _vestingDuration;
        token = IERC20(_tokenAddress);
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function startVesting() external onlyOwner {
        require(startTimestamp == 0, "Vesting: Started.");
        totalVestingAmount = token.balanceOf(address(this));
        require(totalVestingAmount > 0, "Vesting: No tokens.");
        startTimestamp = block.timestamp;
    }
    function release() external {
        require(startTimestamp > 0, "Vesting: Not started.");
        require(msg.sender == beneficiary, "Vesting: Not beneficiary.");
        uint256 vestedAmount = _vestedAmount();
        uint256 releasable = vestedAmount - releasedAmount;
        require(releasable > 0, "Vesting: No tokens to release.");
        releasedAmount += releasable;
        token.transfer(beneficiary, releasable);
        emit TokensReleased(beneficiary, releasable);
    }
    function _vestedAmount() private view returns (uint256) {
        if (block.timestamp < startTimestamp) return 0;
        if (block.timestamp >= startTimestamp + durationSeconds) return totalVestingAmount;
        return (totalVestingAmount * (block.timestamp - startTimestamp)) / durationSeconds;
    }
}