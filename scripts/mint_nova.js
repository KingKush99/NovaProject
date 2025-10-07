// NovaProject/scripts/mint_nova.js

const { ethers } = require("hardhat");

async function main() {
    console.log("--- Starting NovaCoin Minting Script ---");

    // --- Configuration ---
    // This is the LATEST NovaCoin contract address from your deployed_addresses.json
    const novaCoinAddress = "0x8416e9617231230d727070a96606c6313194Ce92"; 
    // --- End Configuration ---

    console.log(`Target NovaCoin Contract: ${novaCoinAddress}`);

    const [deployer] = await ethers.getSigners();
    console.log(`Using Minter (Owner) Account: ${deployer.address}`);

    const novaCoin = await ethers.getContractAt("NovaCoin_ProgrammableSupply", novaCoinAddress);

    console.log("\n--- Checking Balances Before Minting ---");
    const initialDeployerNovaBalance = await novaCoin.balanceOf(deployer.address);
    console.log(`Deployer's Initial NOVA Balance: ${ethers.utils.formatUnits(initialDeployerNovaBalance, 18)} NOVA`);

    console.log("\nAttempting to call mintScheduledSupply...");
    const tx = await novaCoin.connect(deployer).mintScheduledSupply();
    
    console.log("Transaction sent. Waiting for confirmation...");
    await tx.wait(1); // Wait for 1 block confirmation
    
    console.log("✅ Minting successful! Tx Hash:", tx.hash);

    console.log("\n--- Checking Balances After Minting ---");
    const finalDeployerNovaBalance = await novaCoin.balanceOf(deployer.address);
    console.log(`Deployer's Final NOVA Balance: ${ethers.utils.formatUnits(finalDeployerNovaBalance, 18)} NOVA`);
    
    console.log("\n--- Minting Script Complete ---");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });