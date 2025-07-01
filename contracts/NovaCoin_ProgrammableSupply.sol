// Filename: contracts/Core/NovaCoin_ProgrammableSupply.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol"; // Ensure this is imported for initialize

contract NovaCoin_ProgrammableSupply is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000_000 * (10**18); // 1 Trillion whole NOVA
    uint256 public constant PERIOD_DURATION = 1 seconds; // TEMPORARY for fast testing (change back for production)
    uint256 public launchTime;
    mapping(uint256 => uint256) public mintedInPeriod;
    event SupplyMinted(uint256 indexed period, address indexed destination, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialOwner) public initializer {
        __ERC20_init("NovaCoin", "NOVA");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        launchTime = block.timestamp; // Set launch time upon initialization

        // --- DEFINITIVE INITIAL MINT FOR TESTING (REMOVE OR ADJUST FOR PRODUCTION) ---
        // This will mint a large amount of tokens to the deployer/initialOwner immediately upon deployment.
        uint256 initialTestSupply = 500_000_000_000 * (10**18); // Example: 500 Billion NOVA
        _mint(initialOwner, initialTestSupply); // Mint to the initial owner's address
        // --- END DEFINITIVE INITIAL MINT ---
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // This function will now ONLY handle scheduled minting based on PERIOD_DURATION
    function mintScheduledSupply(address destination) external {
        uint256 currentPeriod = (block.timestamp - launchTime) / PERIOD_DURATION;
        uint256 availableToMint = getAvailableToMintForPeriod(currentPeriod);
        require(availableToMint > 0, "No new supply available to mint.");
        mintedInPeriod[currentPeriod] += availableToMint;
        require(totalSupply() + availableToMint <= MAX_SUPPLY, "Exceeds max supply.");
        _mint(destination, availableToMint);
        emit SupplyMinted(currentPeriod, destination, availableToMint);
    }

    function getAvailableToMintForPeriod(uint256 period) public view returns (uint256) {
        uint256 supplyBeforePeriod = 0;
        for (uint i = 0; i < period; i++) {
            supplyBeforePeriod += (MAX_SUPPLY - supplyBeforePeriod) / 2;
        }
        uint256 periodTotalSupply = (MAX_SUPPLY - supplyBeforePeriod) / 2;
        uint256 alreadyMinted = mintedInPeriod[period];
        if (supplyBeforePeriod + periodTotalSupply > MAX_SUPPLY) {
            periodTotalSupply = MAX_SUPPLY - supplyBeforePeriod;
        }
        return periodTotalSupply > alreadyMinted ? periodTotalSupply - alreadyMinted : 0;
    }
}