// scripts/4_fund_test_wallets.js
const { ethers } = require("hardhat");
const fs = require('fs');
const path = require('path');

async function main() {
  console.log("--- Starting Test Wallet Funding Script ---");

  const deployedAddressesPath = path.join(__dirname, '../deployed_addresses.json');
  if (!fs.existsSync(deployedAddressesPath)) {
    console.error("Error: deployed_addresses.json not found. Please deploy contracts first.");
    process.exit(1);
  }
  const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, 'utf8'));

  const [deployer] = await ethers.getSigners();
  console.log(`Using deployer account (funder): ${deployer.address}`);

  const novaCoinProxyAddress = deployedAddresses.NovaCoin_ProgrammableSupply;
  const novaCoin = await ethers.getContractAt("NovaCoin_ProgrammableSupply", novaCoinProxyAddress);

  // --- THIS IS THE SECTION YOU WILL EDIT ---
  const testWalletsToFund = [
    { name: "Sender Test User", address: "0x8D3F87D2658707FEFc06D7E87E97d39826DB5486" },
    { name: "Recipient Test User", address: "0x04d7430cBc79FC548d89a26552E2D046cD6aa3Aa" }
  ];
  // --- END OF SECTION TO EDIT ---

  const novaAmountToFund = ethers.parseUnits("1000", 18);
  const maticAmountToFund = ethers.parseEther("0.1");

  // <<<--- THIS IS THE CORRECTED LINE ---
  for (const wallet of testWalletsToFund) {
    if (!ethers.isAddress(wallet.address) || wallet.address.startsWith("PASTE_")) {
      console.warn(`\nSkipping funding for ${wallet.name} due to invalid or placeholder address: "${wallet.address}"`);
      continue;
    }
    console.log(`\n--- Funding ${wallet.name} (${wallet.address}) ---`);

    try {
      console.log(`Funding ${ethers.formatEther(novaAmountToFund)} NOVA...`);
      const txNova = await novaCoin.connect(deployer).transfer(wallet.address, novaAmountToFund);
      await txNova.wait();
      console.log(`+ Funded ${wallet.name} with ${ethers.formatEther(novaAmountToFund)} NOVA. Tx: ${txNova.hash}`);
    } catch (error) {
      console.error(`Error funding NOVA for ${wallet.name}: ${error.message}`);
    }

    try {
      console.log(`Funding ${ethers.formatEther(maticAmountToFund)} MATIC...`);
      const txMatic = await deployer.sendTransaction({ to: wallet.address, value: maticAmountToFund });
      await txMatic.wait();
      console.log(`+ Funded ${wallet.name} with ${ethers.formatEther(maticAmountToFund)} MATIC. Tx: ${txMatic.hash}`);
    } catch (error) {
      console.error(`Error funding MATIC for ${wallet.name}: ${error.message}`);
    }
  }

  console.log("\n--- Test Wallet Funding Script Complete ---");
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });