// NovaProject/scripts/fund_nftbuyer3.js

const { ethers } = require("hardhat");

async function main() {
    console.log("--- Starting Manual Funding Script for NFTBuyer3 ---");

    // --- Configuration ---
    // This is the LATEST NovaCoin contract address from your deployed_addresses.json
    const novaCoinAddress = "0x8416e9617231230d727070a96606c6313194Ce92"; 
    
    // This is NFTBuyer3's custodial address from your Insomnia/DB
    const nftBuyer3Address = "0x408Cb9D4C645602f91143d98006879e56abFB09d"; 
    
    // Amount to send (1000 NOVA with 18 decimals)
    // This is 1000 followed by 18 zeros.
    const amountToSend = ethers.BigNumber.from("1000000000000000000000"); // Directly use BigNumber
    // --- End Configuration ---

    console.log(`NovaCoin Contract: ${novaCoinAddress}`);
    console.log(`Recipient (NFTBuyer3): ${nftBuyer3Address}`);

    const [deployer] = await ethers.getSigners();
    console.log(`Using Funder Account: ${deployer.address}`);

    const novaCoin = await ethers.getContractAt("NovaCoin_ProgrammableSupply", novaCoinAddress);

    console.log("\n--- Checking Balances Before Transfer ---");
    const deployerNovaBalance = await novaCoin.balanceOf(deployer.address);
    const nftBuyer3NovaBalance = await novaCoin.balanceOf(nftBuyer3Address);

    console.log(`Deployer's NOVA Balance: ${deployerNovaBalance.toString()} (raw units)`);
    console.log(`NFTBuyer3's NOVA Balance: ${nftBuyer3NovaBalance.toString()} (raw units)`);

    if (deployerNovaBalance.lt(amountToSend)) {
        console.error("\nError: Deployer has insufficient NOVA to send. Please run mintScheduledSupply first.");
        process.exit(1);
    }

    console.log(`\nAttempting to transfer ${amountToSend.toString()} (raw units) NOVA to NFTBuyer3...`);
    const tx = await novaCoin.connect(deployer).transfer(nftBuyer3Address, amountToSend);
    
    console.log("Transaction sent. Waiting for confirmation...");
    await tx.wait();
    console.log("✅ NOVA transfer successful to NFTBuyer3! Tx Hash:", tx.hash);

    console.log("\n--- Checking Balances After Transfer ---");
    const finalDeployerNovaBalance = await novaCoin.balanceOf(deployer.address);
    const finalNftBuyer3NovaBalance = await novaCoin.balanceOf(nftBuyer3Address);

    console.log(`Deployer's Final NOVA Balance: ${finalDeployerNovaBalance.toString()} (raw units)`);
    console.log(`NFTBuyer3's Final NOVA Balance: ${finalNftBuyer3NovaBalance.toString()} (raw units)`);
    
    console.log("\n--- Funding Script Complete ---");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });