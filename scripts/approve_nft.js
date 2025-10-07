// NovaProject/scripts/approve_nft.js

const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: '.env' }); // Ensure dotenv is loaded for SELLER_PRIVATE_KEY

// --- DEFINITIVE FIX: Explicitly ensure ethers.utils and ethers.BigNumber are available ---
const _ethersUtils = ethers.utils;
const _ethersBigNumber = ethers.BigNumber;

if (!_ethersUtils || !_ethersBigNumber) {
    console.error("CRITICAL ERROR: ethers.utils or ethers.BigNumber is undefined after Hardhat import.");
    console.error("This indicates a core Hardhat/Ethers setup issue.");
    process.exit(1);
}
// --- END DEFINITIVE FIX ---

async function main() {
    console.log("--- Starting Manual NFT Approval Script ---");

    // --- Configuration ---
    const scriptsDir = __dirname;
    const deployedAddressesPath = path.resolve(scriptsDir, '../deployed_addresses.json');

    let deployedAddresses = {};
    try {
        const fileContent = fs.readFileSync(deployedAddressesPath, 'utf8');
        deployedAddresses = JSON.parse(fileContent);
    } catch (error) {
        console.error(`Error loading deployed_addresses.json. Please ensure it exists directly in your NovaProject folder (e.g., C:\\Users\\Connor\\Desktop\\NovaProject\\deployed_addresses.json) and is valid JSON.`);
        console.error(`Detail: ${error.message}`);
        process.exit(1);
    }

    const novaProfilesAddress = deployedAddresses.NovaProfiles;
    const nftAuctionHouseAddress = deployedAddresses.NFTAuctionHouse;
    const tokenIdToApprove = 2; // Confirmed Token ID for the seller
    // --- End Configuration ---
    
    // --- Use the Seller's Wallet ---
    if (!process.env.SELLER_PRIVATE_KEY) {
        throw new Error("Please add SELLER_PRIVATE_KEY to your .env file!");
    }
    const sellerWallet = new ethers.Wallet(process.env.SELLER_PRIVATE_KEY, ethers.provider);
    console.log(`Using Seller Account: ${sellerWallet.address}`);
    // --- END Seller Wallet Setup ---

    const novaProfiles = await ethers.getContractAt("NovaProfiles", novaProfilesAddress);

    console.log("\nChecking ownership...");
    try {
        const ownerOfToken = await novaProfiles.ownerOf(tokenIdToApprove);
        if (ownerOfToken.toLowerCase() !== sellerWallet.address.toLowerCase()) {
            console.error(`\nError: The signer (${sellerWallet.address}) does not own tokenId ${tokenIdToApprove}.`);
            console.error(`The actual owner is: ${ownerOfToken}`);
            process.exit(1);
        }
        console.log(`Ownership confirmed. Token ID ${tokenIdToApprove} is owned by ${ownerOfToken}.`);
    } catch (error) {
        console.error(`\nError checking ownership for Token ID ${tokenIdToApprove}. This usually means the token does not exist.`);
        console.error(`Detail: ${error.message}`);
        process.exit(1);
    }

    console.log(`\nAttempting to approve NFTAuctionHouse (${nftAuctionHouseAddress}) for Token ID ${tokenIdToApprove}...`);
    
    // --- CORRECTED ROBUST GAS OPTIONS HANDLING (FINAL FINAL ATTEMPT) ---
    let gasOptions = { gasLimit: 150000 }; // Always set a reasonable gas limit

    try {
        const feeData = await ethers.provider.getFeeData();
        
        if (feeData && feeData.maxFeePerGas && feeData.maxPriorityFeePerGas) {
            // For EIP-1559 compatible networks
            gasOptions.maxFeePerGas = feeData.maxFeePerGas.mul(_ethersBigNumber.from(5)); // Using _ethersBigNumber
            gasOptions.maxPriorityFeePerGas = feeData.maxPriorityFeePerGas.mul(_ethersBigNumber.from(5)); // Using _ethersBigNumber
            console.log(`Using EIP-1559 gas: MaxFeePerGas=${_ethersUtils.formatUnits(gasOptions.maxFeePerGas, 'gwei')} Gwei, MaxPriorityFeePerGas=${_ethersUtils.formatUnits(gasOptions.maxPriorityFeePerGas, 'gwei')} Gwei`); // Using _ethersUtils
        } else if (feeData && feeData.gasPrice) {
            // Fallback for networks that only support legacy gasPrice (or when feeData.maxFee/Priority are null)
            gasOptions.gasPrice = feeData.gasPrice.mul(_ethersBigNumber.from(5)); // Using _ethersBigNumber
            console.log(`Using legacy gasPrice: ${_ethersUtils.formatUnits(gasOptions.gasPrice, 'gwei')} Gwei`); // Using _ethersUtils
        } else {
            // Final fallback if no fee data is available at all
            gasOptions.gasPrice = _ethersUtils.parseUnits('30', 'gwei'); // Using _ethersUtils
            console.log(`Using default fallback gasPrice: ${_ethersUtils.formatUnits(gasOptions.gasPrice, 'gwei')} Gwei`); // Using _ethersUtils
        }
    } catch (gasError) {
        console.warn(`Could not fetch fee data from provider (${gasError.message}). Falling back to default gasPrice.`);
        gasOptions.gasPrice = _ethersUtils.parseUnits('30', 'gwei'); // Using _ethersUtils
    }
    // --- END CORRECTED ROBUST GAS OPTIONS HANDLING ---

    const tx = await novaProfiles.connect(sellerWallet).approve(
        nftAuctionHouseAddress, 
        tokenIdToApprove,
        gasOptions // Pass the gas options
    );
    
    console.log("Approval transaction sent. Hash (before wait):", tx.hash); 

    console.log("Waiting for confirmation...");
    await tx.wait(1); // Wait for 1 confirmation
    console.log("✅ Approval successful! Tx Hash:", tx.hash);

    console.log("\n--- Approval Script Complete ---");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });