// scripts/2_deploy_apps.js
const { ethers, upgrades } = require("hardhat");
const fs = require('fs');

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("--- Starting Application Layer Deployment ---");
  console.log("Deploying with account:", deployer.address);

  let deployedAddresses = {};
  if (fs.existsSync("deployed_addresses.json")) {
    deployedAddresses = JSON.parse(fs.readFileSync("deployed_addresses.json", "utf8"));
  }

  const novaRegistryAddress = deployedAddresses["NovaRegistry"];
  if (!novaRegistryAddress) {
    throw new Error("NovaRegistry address not found. Please run 1_deploy_core.js first.");
  }
  console.log("Using NovaRegistry at:", novaRegistryAddress);

  const contractNames = [
    "NovaPolicyRules", "NFTAuctionHouse", "NFTOfferBook", "CollectorSetManager", "NovaProfiles", 
    "NovaNameService", "NovaKYCVerifier", "NovaMarketplace", "NovaPoints", "NovaReputation", 
    "NovaReferral", "NovaChat", "NovaFeed", "NovaStreamerPayout", "NovaGameBridge"
  ];

  for (const name of contractNames) {
    console.log(`Deploying ${name}...`);
    const ContractFactory = await ethers.getContractFactory(name);
    const args = name.includes("Marketplace") || name.includes("OfferBook") ? [deployer.address, novaRegistryAddress] : [deployer.address];
    const deployedContract = await upgrades.deployProxy(ContractFactory, args, { initializer: 'initialize', kind: 'uups' });
    const contractAddress = await deployedContract.getAddress();
    deployedAddresses[name] = contractAddress;
    console.log(`-> ${name} deployed to:`, contractAddress);
  }

  fs.writeFileSync("deployed_addresses.json", JSON.stringify(deployedAddresses, null, 2));
  console.log("\nAll application contract addresses saved to deployed_addresses.json");
}

main().catch((error) => { console.error(error); process.exit(1); });