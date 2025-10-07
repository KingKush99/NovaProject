// scripts/verify.js

const fs = require('fs');
const path = require('path');
const { getImplementationAddress } = require('@openzeppelin/upgrades-core'); // Import from OpenZeppelin Utilities

// =========================================================================================================
// IMPORTANT: This script verifies contracts. For proxies, it verifies implementation and then
// relies on Hardhat's standard verify:verify to link the proxy, or requires manual linking.
// =========================================================================================================

// --- Configuration: List of Proxy Contracts to Verify ---
const contractsToVerify = [
  'NovaRegistry',
  'NovaCoin_ProgrammableSupply', // No explicit proxy config here, will rely on standard verify
  'NovaTreasury',
  'TokenVesting',
  'NovaPolicyRules',
  'NFTAuctionHouse',
  'NFTOfferBook',
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

  const uniqueContractsToVerify = [...new Set(contractsToVerify)]; // Remove potential duplicates

  for (const contractName of uniqueContractsToVerify) {
    const proxyAddress = deployedAddresses[contractName];

    if (!proxyAddress) {
      console.warn(`--> WARNING: Proxy address for ${contractName} not found in deployed_addresses.json. Skipping verification.`);
      continue;
    }

    console.log(`\nVerifying ${contractName} at proxy address ${proxyAddress}...`);

    let implementationAddress;
    try {
      // 1. Get the implementation address dynamically from the proxy on-chain
      // This uses the getImplementationAddress from '@openzeppelin/upgrades-core' which is imported at the top.
      implementationAddress = await getImplementationAddress(hre.ethers.provider, proxyAddress); 
      console.log(`Discovered implementation for ${contractName}: ${implementationAddress}`);

      // 2. Verify the implementation contract first
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
          console.error(`Failed to verify implementation contract at ${implementationAddress}: ${error.message}`);
        }
      }

      // 3. Verify and link the proxy using the standard hardhat-verify
      try {
        await hre.run("verify:verify", {
          address: proxyAddress,
        });
        console.log(`Successfully verified proxy ${contractName} on the block explorer.`);
        console.log(`--> INFO: Proxy for ${contractName} (${proxyAddress}) is linked.`);
      } catch (error) {
        if (error.message.includes("Already Verified") || error.message.includes("Contract source code already verified") || error.message.includes("Failed to verify ERC1967Proxy contract") && error.message.includes("Already Verified")) {
          console.log(`--> INFO: Proxy for ${contractName} (${proxyAddress}) is already verified.`);
        } else {
          console.error(`Failed to verify proxy contract at ${proxyAddress}: ${error.message}`);
          console.error(`--> Action required: You might need to manually verify this proxy on Polygonscan. Go to https://amoy.polygonscan.com/proxyContractChecker and link ${proxyAddress} to ${implementationAddress}.`);
        }
      }
      
      console.log(`Check it out on Amoy Polygonscan: https://amoy.polygonscan.com/address/${proxyAddress}#code`);

    } catch (error) {
      console.error(`\n--> CRITICAL FAILED to process verification for ${contractName} at ${proxyAddress}:`, error.message);
    }
    await new Promise(resolve => setTimeout(resolve, 30000)); // 30-second delay
  }

  console.log("\n--- Verification Script Complete ---");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });