// scripts/verify.js

const { getImplementationAddress } = require('@openzeppelin/upgrades-core'); // Used to dynamically get implementation address
const fs = require('fs');
const path = require('path');

// =========================================================================================================
// IMPORTANT: This script automatically verifies your deployed proxies and their implementations.
// It uses deployed_addresses.json (which contains proxy addresses) to find implementations on-chain.
// =========================================================================================================

// --- Configuration: List of Proxy Contracts to Verify ---
// This list should just contain the main proxy names from your deployed_addresses.json.
// The script will dynamically find their implementations.
const contractsToVerify = [
  'NovaRegistry',
  'NovaCoin_ProgrammableSupply',
  'NovaTreasury',
  'TokenVesting',
  'NovaPolicyRules',
  'NFTAuctionHouse',
  'NFTOfferBook',
  'NFTOfferBook', // Duplicated - removed later
  'CollectorSetManager',
  'NovaProfiles',
  'NovaNameService',
  'NovaKYCVerifier',
  'NovaMarketplace',
  'NovaPoints',
  'NovaReputation',
  'NovaReferral',
  'NovaChat',
  'NovaFeed',
  'NovaStreamerPayout',
  'NovaGameBridge'
];

// --- Load Deployed Addresses (Proxy Addresses Only) ---
const deployedAddressesPath = path.join(__dirname, '../deployed_addresses.json');
const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, 'utf8'));

async function main() {
  console.log("--- Starting Automated Mass Verification Process ---");
  console.log("Found the following contracts to verify:", contractsToVerify);

  // Remove duplicates from contractsToVerify (if any)
  const uniqueContractsToVerify = [...new Set(contractsToVerify)];

  for (const contractName of uniqueContractsToVerify) { // Iterate unique contract names
    const proxyAddress = deployedAddresses[contractName];

    if (!proxyAddress) {
      console.warn(`--> WARNING: Proxy address for ${contractName} not found in deployed_addresses.json. Skipping verification.`);
      continue;
    }

    console.log(`\nVerifying ${contractName} at proxy address ${proxyAddress}...`);

    try {
      // 1. Get the implementation address dynamically from the proxy on-chain
      const implementationAddress = await getImplementationAddress(hre.ethers.provider, proxyAddress);
      console.log(`Discovered implementation for ${contractName}: ${implementationAddress}`);

      // 2. Verify the implementation contract
      try {
        await hre.run("verify:verify", {
          address: implementationAddress,
          constructorArguments: [], // Adjust if your implementation contract's constructor has arguments
        });
        console.log(`Successfully verified implementation contract for ${contractName} at ${implementationAddress}`);
      } catch (error) {
        if (error.message.includes("Already Verified") || error.message.includes("Contract source code already verified")) {
          console.log(`--> INFO: Implementation for ${contractName} (${implementationAddress}) is already verified.`);
        } else {
          console.error(`Failed to verify implementation contract for ${contractName} at ${implementationAddress}: ${error.message}`);
          throw error; // If implementation verification fails, proxy linking will also fail.
        }
      }

      // 3. Verify and link the proxy (this also tries to verify the proxy's bytecode)
      try {
        await hre.run("verify:verify", {
          address: proxyAddress,
        });
        console.log(`Successfully verified proxy contract ${contractName} at ${proxyAddress}`);
      } catch (error) {
        if (error.message.includes("Already Verified") || error.message.includes("Contract source code already verified")) {
          console.log(`--> INFO: Proxy for ${contractName} (${proxyAddress}) is already verified.`);
        } else {
          console.error(`Failed to verify proxy contract at ${proxyAddress}: ${error.message}`);
          // Don't throw here, as long as implementation is verified, linking might still succeed or be handled by Etherscan
        }
      }

      // 4. Force linking of proxy to implementation (especially for stubborn cases like NovaCoin_ProgrammableSupply)
      // This is crucial for the "Read as Proxy" / "Write as Proxy" tabs to appear consistently on Polygonscan.
      try {
        console.log(`Attempting to link proxy ${proxyAddress} with implementation ${implementationAddress} via Defender/Etherscan API...`);
        // The defender:verify-proxy task is part of @openzeppelin/hardhat-upgrades
        // It specifically helps link proxies on Etherscan/Polygonscan.
        await hre.run("defender:verify-proxy", {
          address: proxyAddress,
          network: hre.network.name, // Pass the current network name (e.g., 'amoy')
          etherscanApiKey: process.env.POLYGONSCAN_API_KEY, // Ensure API key is passed correctly
        });
        console.log(`Successfully linked proxy ${contractName} (${proxyAddress}) to implementation.`);
        console.log(`Check it out on Amoy Polygonscan: https://amoy.polygonscan.com/address/${proxyAddress}#code`);

      } catch (error) {
        if (error.message.includes("proxy is already verified")) {
          console.log(`--> INFO: Proxy for ${contractName} (${proxyAddress}) is already linked and verified.`);
        } else {
          console.error(`Failed to link proxy ${proxyAddress} to implementation ${implementationAddress}: ${error.message}`);
        }
      }
      
    } catch (error) {
      console.error(`\n--> CRITICAL FAILED to process verification for ${contractName} at ${proxyAddress}:`, error.message);
    }
    await new Promise(resolve => setTimeout(resolve, 5000)); // Wait 5 seconds before next verification
  }

  console.log("\n--- Verification Script Complete ---");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });