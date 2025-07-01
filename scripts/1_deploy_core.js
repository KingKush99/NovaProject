// scripts/1_deploy_core.js
// This script deploys the 4 foundational contracts of your ecosystem.

const { ethers, upgrades } = require("hardhat");
const fs = require('fs');

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("--- Starting Core Deployment (Step 1 of 3) ---");
  console.log("Deploying core infrastructure with account:", deployer.address);

  // This object will hold the results of this script
  const deployedAddresses = {};

  // --- TIER 1: THE FOUNDATIONAL PILLAR ---
  console.log("\nDeploying NovaRegistry...");
  const NovaRegistry = await ethers.getContractFactory("NovaRegistry");
  const novaRegistry = await upgrades.deployProxy(NovaRegistry, [deployer.address], { initializer: 'initialize', kind: 'uups' });
  const novaRegistryAddress = await novaRegistry.getAddress();
  deployedAddresses["NovaRegistry"] = novaRegistryAddress;
  console.log("-> NovaRegistry deployed to:", novaRegistryAddress);

  // --- TIER 2: THE CORE ECONOMIC ENGINE ---
  console.log("\nDeploying NovaCoin...");
  const NovaCoin = await ethers.getContractFactory("NovaCoin_ProgrammableSupply");
  const novaCoin = await upgrades.deployProxy(NovaCoin, [deployer.address], { initializer: 'initialize', kind: 'uups' });
  const novaCoinAddress = await novaCoin.getAddress();
  deployedAddresses["NovaCoin_ProgrammableSupply"] = novaCoinAddress;
  console.log("-> NovaCoin deployed to:", novaCoinAddress);
  
  console.log("\nDeploying NovaTreasury...");
  const NovaTreasury = await ethers.getContractFactory("NovaTreasury");
  const novaTreasury = await upgrades.deployProxy(NovaTreasury, [deployer.address], { initializer: 'initialize', kind: 'uups' });
  const novaTreasuryAddress = await novaTreasury.getAddress();
  deployedAddresses["NovaTreasury"] = novaTreasuryAddress;
  console.log("-> NovaTreasury deployed to:", novaTreasuryAddress);

  console.log("\nDeploying TokenVesting...");
  const VESTING_DURATION = 10 * 365 * 24 * 60 * 60; // 10 years in seconds
  const TokenVesting = await ethers.getContractFactory("TokenVesting");
  const tokenVesting = await upgrades.deployProxy(TokenVesting, [deployer.address, deployer.address, VESTING_DURATION, novaCoinAddress], { 
    initializer: 'initialize', 
    kind: 'uups' 
  });
  const tokenVestingAddress = await tokenVesting.getAddress();
  deployedAddresses["TokenVesting"] = tokenVestingAddress;
  console.log("-> TokenVesting deployed to:", tokenVestingAddress);
  
  // Save the addresses of the deployed core contracts to a new file.
  // The next script (2_deploy_apps.js) will read this file to get the registry's address.
  fs.writeFileSync("deployed_addresses.json", JSON.stringify(deployedAddresses, null, 2));
  
  console.log("\n--- Core Deployment Complete ---");
  console.log("Core contract addresses saved to deployed_addresses.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });