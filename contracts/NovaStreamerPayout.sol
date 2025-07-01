// Filename: contracts/Streaming/NovaStreamerPayout.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaStreamerPayout is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    event PayoutsDistributed(uint256 totalAmount, uint256 recipientCount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    receive() external payable {}
    function distributePayouts(address payable[] calldata recipients, uint256[] calldata amounts) external onlyOwner {
        require(recipients.length == amounts.length, "Payouts: Mismatched arrays.");
        uint256 totalAmount = 0;
        for (uint i = 0; i < amounts.length; i++) { totalAmount += amounts[i]; }
        require(address(this).balance >= totalAmount, "Payouts: Insufficient funds.");
        for (uint i = 0; i < recipients.length; i++) {
            (bool success, ) = recipients[i].call{value: amounts[i]}("");
            require(success, "Payouts: Transfer failed.");
        }
        emit PayoutsDistributed(totalAmount, recipients.length);
    }
}