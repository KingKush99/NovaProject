// scripts/3_register_and_fund.js

const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("--- Starting Final Configuration and Funding ---");

  const deployedAddressesPath = path.join(__dirname, '../deployed_addresses.json');
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, 'utf8'));

  const novaRegistryAddress = deployedAddresses.NovaRegistry;
  const novaRegistry = await ethers.getContractAt("NovaRegistry", novaRegistryAddress);

  // Get the deployer (admin) account
  const [deployer] = await ethers.getSigners();
  console.log(`Using deployer account: ${deployer.address}`);

  // Step 1: Registering contracts with NovaRegistry
  console.log("\nStep 1: Registering contracts...");
  const contractsToRegister = {
    NovaCoin_ProgrammableSupply: "NOVA_COIN__PROGRAMMABLE_SUPPLY",
    NovaTreasury: "NOVA_TREASURY",
    TokenVesting: "TOKEN_VESTING",
    NovaPolicyRules: "NOVA_POLICY_RULES",
    NFTAuctionHouse: "N_F_T_AUCTION_HOUSE",
    NFTOfferBook: "N_F_T_OFFER_BOOK",
    CollectorSetManager: "COLLECTOR_SET_MANAGER",
    NovaProfiles: "NOVA_PROFILES",
    NovaNameService: "NOVA_NAME_SERVICE",
    NovaKYCVerifier: "NOVA_K_Y_C_VERIFIER",
    NovaMarketplace: "NOVA_MARKETPLACE",
    NovaPoints: "NOVA_POINTS",
    NovaReputation: "NOVA_REPUTATION",
    NovaReferral: "NOVA_REFERRAL",
    NovaChat: "NOVA_CHAT",
    NovaFeed: "NOVA_FEED",
    NovaStreamerPayout: "NOVA_STREAMER_PAYOUT",
    NovaGameBridge: "NOVA_GAME_BRIDGE"
  };

  for (const contractName in contractsToRegister) {
    const key = contractsToRegister[contractName];
    const contractAddress = deployedAddresses[contractName];
    if (contractAddress) {
      try {
        const tx = await novaRegistry.registerContract(ethers.encodeBytes32String(key), contractAddress);
        await tx.wait();
        console.log(`+ Registered ${contractName} with key ${key}`);
      } catch (error) {
        if (error.message.includes("Key already registered")) {
          console.log(`- ${contractName} with key ${key} already registered.`);
        } else {
          console.error(`Error registering ${contractName} with key ${key}:`, error.message);
        }
      }
    } else {
      console.warn(`Warning: ${contractName} address not found in deployed_addresses.json`);
    }
  }

  // Step 2: Minting initial supply is now handled by the NovaCoin_ProgrammableSupply contract's initializer.
  // The deployer's wallet will automatically receive the initial supply upon deployment.
  console.log("\nStep 2: Initial supply handled by contract initializer. Skipping direct minting in script.");
  
  // Step 3: Ensuring deployer has enough MATIC for gas (primarily for subsequent transactions).
  console.log("\nStep 3: Ensuring deployer has enough MATIC...");
  const deployerBalance = await ethers.provider.getBalance(deployer.address);
  if (deployerBalance < ethers.parseEther("0.01")) { // Check if less than 0.01 MATIC
    console.log(`Deployer balance: ${ethers.formatEther(deployerBalance)} MATIC. Consider funding via faucet if needed for future transactions.`);
  } else {
    console.log(`Deployer has sufficient MATIC: ${ethers.formatEther(deployerBalance)} MATIC.`);
  }

  console.log("\n--- Final Configuration and Funding Complete ---");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });