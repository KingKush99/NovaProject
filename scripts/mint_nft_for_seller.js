// NovaProject/scripts/mint_nft_for_seller.js

const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
    console.log("--- Starting Manual NFT Minting Script for Seller ---");

    // --- Configuration ---
    if (!process.env.SELLER_PRIVATE_KEY) {
        throw new Error("Please add SELLER_PRIVATE_KEY for your new seller to your .env file!");
    }
    
    const deployedAddressesPath = path.join(__dirname, '../deployed_addresses.json');
    const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, 'utf8'));

    const novaProfilesAddress = deployedAddresses.NovaProfiles;

    const username = "FinalSeller2_ScriptMint";
    const ipfsCid = "QmQ9kxKuexYi2LpTWw3XF2Px5iX6tRzg6dHUjdJFe99fQJ";
    const contentHash = `ipfs://${ipfsCid}`;
    // --- End Configuration ---

    const sellerWallet = new ethers.Wallet(process.env.SELLER_PRIVATE_KEY, ethers.provider);
    console.log(`Using Seller Account: ${sellerWallet.address}`);
    
    const novaProfiles = await ethers.getContractAt("NovaProfiles", novaProfilesAddress);

    console.log("\nChecking seller's current NFT balance...");
    const initialBalance = await novaProfiles.balanceOf(sellerWallet.address);
    console.log(`Initial NFT Balance: ${initialBalance.toString()}`);

    if (initialBalance > 0) {
        console.error("\nError: This wallet already owns a profile NFT. Cannot mint another.");
        process.exit(1);
    }

    // --- FIX: Use BigInt arithmetic for gas price calculation ---
    const feeData = await ethers.provider.getFeeData();
    const gasOptions = {
        maxFeePerGas: feeData.maxFeePerGas * 5n, // Use 'n' suffix for BigInt literal
        maxPriorityFeePerGas: feeData.maxPriorityFeePerGas * 5n, // Use 'n' suffix for BigInt literal
    };
    console.log(`\nUsing aggressive dynamic gas price: maxFeePerGas=${ethers.utils.formatUnits(gasOptions.maxFeePerGas, 'gwei')} Gwei`);
    
    console.log(`\nAttempting to mint NFT profile for ${username}...`);
    const tx = await novaProfiles.connect(sellerWallet).createProfile(username, contentHash, gasOptions);
    
    console.log("Transaction sent. Waiting for confirmation...");
    await tx.wait(1); // Wait for 1 block confirmation
    console.log("✅ NFT Mint successful! Tx Hash:", tx.hash);

    console.log("\n--- Minting Script Complete ---");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });