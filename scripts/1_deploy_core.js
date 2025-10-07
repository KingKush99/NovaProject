// scripts/1_deploy_core.js (TEMPORARY: FOR REDEPLOYING ONLY NFTAuctionHouse)

const { ethers, upgrades } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("--- Starting Selective Contract Deployment (NFTAuctionHouse Only) ---");

  const [deployer] = await ethers.getSigners();
  console.log(`Using deployer account: ${deployer.address}`);

  // Load existing addresses to preserve them, if possible.
  const outputPath = path.join(__dirname, '../deployed_addresses.json');
  let deployedAddresses = {};
  try {
    if (fs.existsSync(outputPath)) {
        deployedAddresses = JSON.parse(fs.readFileSync(outputPath, 'utf8'));
        console.log("Loaded existing deployed_addresses.json.");
    }
  } catch (error) {
    console.warn(`Could not load existing deployed_addresses.json: ${error.message}. Starting fresh.`);
  }

  // --- Ensure necessary addresses exist for initialization (if they are arguments to NFTAuctionHouse) ---
  // In your NFTAuctionHouse.sol, initialize only takes 'initialOwnerAddress'.
  // If it took NovaRegistry or NovaCoin address, you'd need those loaded here:
  const initialOwnerAddress = deployer.address;
  // If communityFundAddress is part of NFTAuctionHouse initializer, define it:
  // const communityFundAddress = "0x7c00e73d0c8cD8e036BE4b128d9a2454f3aaeD50"; 

  // --- Deploy NFTAuctionHouse ONLY ---
  console.log("\nDeploying NFTAuctionHouse...");
  const NFTAuctionHouse = await ethers.getContractFactory("NFTAuctionHouse");
  // Ensure correct initializer arguments based on your NFTAuctionHouse.sol initialize function
  const nftAuctionHouse = await upgrades.deployProxy(NFTAuctionHouse, [initialOwnerAddress], { initializer: 'initialize', kind: 'uups' });
  await nftAuctionHouse.waitForDeployment();
  const nftAuctionHouseAddress = await nftAuctionHouse.getAddress();
  const nftAuctionHouseImplementationAddress = await upgrades.erc1967.getImplementationAddress(nftAuctionHouseAddress);
  
  // Update only NFTAuctionHouse address in the object
  deployedAddresses.NFTAuctionHouse = nftAuctionHouseAddress;
  deployedAddresses.NFTAuctionHouse_Implementation = nftAuctionHouseImplementationAddress;
  
  console.log(`NFTAuctionHouse deployed to: ${nftAuctionHouseAddress}`);
  console.log(`NFTAuctionHouse implementation deployed to: ${nftAuctionHouseImplementationAddress}`);

  // --- End Deploy NFTAuctionHouse ONLY ---


  // Save the updated deployed addresses to a JSON file
  fs.writeFileSync(outputPath, JSON.stringify(deployedAddresses, null, 2));
  console.log(`\nUpdated deployed_addresses.json with new NFTAuctionHouse address.`);
  console.log(`\n--- Selective Contract Deployment (NFTAuctionHouse Only) Complete ---`);

  // --- IMPORTANT: Output the new NFTAuctionHouse address for easy copy-pasting to CamAppServer/config/contractAddresses.json ---
  console.log("\n--- NEW NFTAUCTIONHOUSE AMOY ADDRESS FOR CAMAPPSERVER ---");
  console.log(`"NFTAuctionHouse": "${nftAuctionHouseAddress}",`);
  console.log("---------------------------------------------------------------");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });