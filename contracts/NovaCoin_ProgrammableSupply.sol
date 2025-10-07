// Filename: contracts/Core/NovaCoin_ProgrammableSupply.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30; // Using 0.8.30

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract NovaCoin_ProgrammableSupply is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    // CORRECTED: Use 'e' notation for large constant values to avoid potential literal overflow/misinterpretation
    // 1 Trillion = 1,000,000,000,000 * 10^18 (with decimals)
    uint256 public constant MAX_TOTAL_SUPPLY = 1e12 * 1e18; // 1 Trillion whole NOVA with 18 decimals

    // TEMPORARY FOR TESTING! REMEMBER TO CHANGE BACK TO 365 days FOR PRODUCTION!
    uint256 public constant PERIOD_DURATION = 1; // Yearly minting periods (1 second for testing)
    uint256 public constant DECIMAL_FACTOR = 1e18; // 1,000,000,000,000,000,000

    // --- Initial Emission Phase Constants (First 10 years / 10 periods) ---
    uint256 public constant INITIAL_EMISSION_PERIODS = 10;
    // 4 Billion NOVA = 4,000,000,000 * 10^18
    uint256 public constant OWNER_YEARLY_SHARE_INITIAL = 4e9 * 1e18; // 4 Billion with 18 decimals

    // --- Overall Halving Emission Constants (Applies from launch) ---
    // TEMPORARY FOR TESTING! REMEMBER TO CHANGE BACK TO 10 * 365 days FOR PRODUCTION!
    uint256 public constant HALVING_DECADE_DURATION = 10 * 1; // Halving period for the base yearly mint amount (10 seconds for testing)
    
    // 100 Billion NOVA = 100,000,000,000 * 10^18
    uint256 public constant INITIAL_BASE_YEARLY_MINT_AMOUNT = 100e9 * 1e18; // 100 Billion with 18 decimals

    address public communityFundAddress; // Address to send community portion of yearly mint

    uint256 public lastMintPeriodTimestamp; // Tracks the timestamp of the last successful mint (for annual check)
    uint256 public currentEmissionPeriodIndex; // Tracks which 1-year period we are in (0 for first year, 1 for second, etc.)

    event SupplyMinted(uint256 indexed periodIndex, address indexed destination, uint256 amount);
    event CommunityFundAddressSet(address indexed _communityFundAddress);
    event HalvingOccurred(uint256 indexed periodIndex, uint256 newBaseMintAmount);


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialOwner, address _communityFundAddress) public initializer {
        __ERC20_init("NovaCoin", "NOVA");
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        require(_communityFundAddress != address(0), "Community fund address cannot be zero.");
        communityFundAddress = _communityFundAddress;
        emit CommunityFundAddressSet(_communityFundAddress);

        lastMintPeriodTimestamp = block.timestamp; // Set initial timestamp for the first period
        currentEmissionPeriodIndex = 0; // Initialize to the first period (index 0)
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Calculates the base amount of tokens to be minted in a given period, considering halvings.
     * @param _periodIndex The current 1-year period index (0, 1, 2...).
     * @return The base amount for that period before specific owner/community splits.
     */
    function _calculateBaseAmountForPeriod(uint256 _periodIndex) internal pure returns (uint256) {
        // Calculate current halving period based on 10-year intervals
        uint256 numHalvings = _periodIndex / (HALVING_DECADE_DURATION / PERIOD_DURATION);

        uint256 baseMintAmount = INITIAL_BASE_YEARLY_MINT_AMOUNT;
        for (uint256 i = 0; i < numHalvings; i++) {
            baseMintAmount /= 2; // Halve the base amount
        }

        // Ensure baseMintAmount does not fall below a practical minimum (e.g., 1 NOVA)
        if (baseMintAmount < 1 * DECIMAL_FACTOR) {
            baseMintAmount = 0;
        }
        return baseMintAmount;
    }

    /**
     * @notice Allows the owner to mint scheduled supply for the current period.
     * This function can only be called once per PERIOD_DURATION (e.g., once per year).
     * It distributes tokens based on the defined schedule.
     * Initial 10 years have owner/community split, then full amount goes to community.
     */
    function mintScheduledSupply() external onlyOwner {
        require(block.timestamp >= lastMintPeriodTimestamp + PERIOD_DURATION, "Minting period not elapsed.");

        uint256 currentSupply = totalSupply();
        // Ensure we don't exceed max supply before even calculating
        require(currentSupply < MAX_TOTAL_SUPPLY, "Max supply reached. No more tokens can be minted.");

        uint256 baseAmountForThisPeriod = _calculateBaseAmountForPeriod(currentEmissionPeriodIndex);
        
        // If the calculated base amount is zero, there's nothing more to mint via this function.
        if (baseAmountForThisPeriod == 0) {
            revert("No new supply available for this period, or all emissions complete.");
        }

        uint256 communityAmountToMint = 0;
        uint256 ownerAmountToMint = 0;
        uint256 totalAmountToMintThisPeriod; // Will be set after allocation logic

        if (currentEmissionPeriodIndex < INITIAL_EMISSION_PERIODS) {
            // --- Logic for the first 10 years (Initial Emission Periods) ---
            ownerAmountToMint = OWNER_YEARLY_SHARE_INITIAL;
            
            // Ensure owner's share doesn't exceed the total base amount for the period
            if (ownerAmountToMint > baseAmountForThisPeriod) {
                ownerAmountToMint = baseAmountForThisPeriod; // Cap owner's share at base amount
            }
            communityAmountToMint = baseAmountForThisPeriod - ownerAmountToMint;
            
        } else {
            // --- Logic for Post-Initial Emission Periods (Years 11 until MAX_TOTAL_SUPPLY or 2200) ---
            // After the initial 10 years, the entire calculated base amount goes to the community fund.
            communityAmountToMint = baseAmountForThisPeriod;
            ownerAmountToMint = 0; // Owner's specific yearly share stops after 10 years
        }

        totalAmountToMintThisPeriod = communityAmountToMint + ownerAmountToMint;

        // Final check to ensure total mint doesn't exceed MAX_TOTAL_SUPPLY
        // This is important for the very last period, which might be partial
        if (currentSupply + totalAmountToMintThisPeriod > MAX_TOTAL_SUPPLY) {
            totalAmountToMintThisPeriod = MAX_TOTAL_SUPPLY - currentSupply;
            
            // Re-distribute proportionally if it's a mixed owner/community period
            if (currentEmissionPeriodIndex < INITIAL_EMISSION_PERIODS) {
                uint256 originalTotal = communityAmountToMint + ownerAmountToMint;
                if (originalTotal > 0) { // Avoid division by zero if originalTotal happens to be 0
                    communityAmountToMint = (totalAmountToMintThisPeriod * communityAmountToMint) / originalTotal;
                    ownerAmountToMint = totalAmountToMintThisPeriod - communityAmountToMint;
                } else { // Should not be reached if baseAmountForThisPeriod > 0
                    communityAmountToMint = 0;
                    ownerAmountToMint = 0;
                }
            } else { // Post-initial phase, all to community
                communityAmountToMint = totalAmountToMintThisPeriod;
                ownerAmountToMint = 0;
            }
        }

        // Mint tokens if there's an actual amount to mint after all calculations
        if (totalAmountToMintThisPeriod > 0) {
            if (communityAmountToMint > 0) {
                _mint(communityFundAddress, communityAmountToMint);
                emit SupplyMinted(currentEmissionPeriodIndex, communityFundAddress, communityAmountToMint);
            }
            if (ownerAmountToMint > 0) {
                _mint(owner(), ownerAmountToMint);
                emit SupplyMinted(currentEmissionPeriodIndex, owner(), ownerAmountToMint);
            }
        } else {
            // This case might be hit if the remaining supply is extremely small or zero
            // and proposed amounts get rounded down to zero, even if MAX_TOTAL_SUPPLY not reached.
            revert("Calculated mint amount is zero. Emission complete or too small to mint.");
        }
        
        // Emit halving event if this period is the start of a new halving decade
        if (currentEmissionPeriodIndex > 0 && currentEmissionPeriodIndex % (HALVING_DECADE_DURATION / PERIOD_DURATION) == 0) {
             emit HalvingOccurred(currentEmissionPeriodIndex, _calculateBaseAmountForPeriod(currentEmissionPeriodIndex));
        }

        lastMintPeriodTimestamp = block.timestamp; // Update timestamp for the next period
        currentEmissionPeriodIndex++; // Always increment period index for chronological tracking
    }

    /**
     * @notice Allows the owner to change the community fund address.
     * @param _newCommunityFundAddress The new address for the community fund.
     */
    function setCommunityFundAddress(address _newCommunityFundAddress) external onlyOwner {
        require(_newCommunityFundAddress != address(0), "New community fund address cannot be zero.");
        communityFundAddress = _newCommunityFundAddress;
        emit CommunityFundAddressSet(_newCommunityFundAddress);
    }

    // Helper function to get current expected yearly base amount (for UI display or external calls)
    function getCurrentExpectedBaseMintAmount() public view returns (uint256) {
        // Use currentEmissionPeriodIndex + 1 if you want the amount for the *next* period
        // For the current period, it's just currentEmissionPeriodIndex
        return _calculateBaseAmountForPeriod(currentEmissionPeriodIndex);
    }
}