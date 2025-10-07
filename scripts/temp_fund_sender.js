// scripts/temp_fund_sender.js
const { ethers } = require("hardhat"); // Hardhat's ethers is available as 'ethers' directly
const fs = require('fs');
const path = require('path');

async function main() {
    console.log("--- Starting TEMP Sender Funding Script ---");

    const deployedAddressesPath = path.join(__dirname, '../deployed_addresses.json');
    if (!fs.existsSync(deployedAddressesPath)) {
        console.error("Error: deployed_addresses.json not found. Please deploy contracts first.");
        process.exit(1);
    }
    const deployedAddresses = JSON.parse(fs.readFileSync(deployedAddressesPath, 'utf8'));

    // Get deployer (admin) account
    const [deployer] = await ethers.getSigners();
    console.log(`Using deployer account: ${deployer.address}`);

    // --- CRITICAL FIX: HARDCODE NOVACOIN IMPLEMENTATION ADDRESS ---
    // This bypasses the getImplementationAddress helper function which was failing.
    // Make sure this is YOUR LATEST NovaCoin Implementation Address!
    const novaCoinImplementationAddress = "0xC8922e3f4804C9a588bef3116f3620902714628F"; 
    // ^^^ REPLACE with the actual latest NovaCoin Implementation Address from your Hardhat deploy/verify logs ^^^
    // This should be the address from your LAST successful 1_deploy_core.js run's output.
    // Example: 0xC8922e3f4804C9a588bef3116f3620902714628F (from previous logs)
    // If you redeploy again, you will need to update this address!
    // --- END CRITICAL FIX ---
    
    // Connect deployer signer to the NovaCoin contract instance
    const novaCoin = await ethers.getContractAt("NovaCoin_ProgrammableSupply", novaCoinImplementationAddress, deployer); 

    // Define test wallet addresses (replace with ACTUAL addresses from your CURRENT Insomnia users)
    // These are examples. Replace with the custodial addresses from your Insomnia REGISTER responses.
    const senderCustodialAddress = "0xb45aca6eb28e6710c3e0a9df376ef216fd1a86e7"; // db_test_user_final@example.com's address (ID 1)
    const recipientCustodialAddress = "0xa2a7053b016426be2bba4f7f08823824ae75d9f"; // db_recipient@example.com's address (ID 5)
    
    const novaAmountToFund = ethers.parseUnits("1000", 18); // Fund 1000 NOVA to each test wallet
    const maticAmountToFund = ethers.parseEther("0.1");   // Fund 0.1 MATIC to each test wallet (for gas)

    for (const wallet of [{ name: "Sender Test User", address: senderCustodialAddress }, { name: "Recipient Test User", address: recipientCustodialAddress }]) {
        console.log(`\n--- Funding ${wallet.name} (${wallet.address}) ---`);

        // Check deployer's current NovaCoin balance (before any funding)
        const deployerNovaBalanceBeforeScript = await novaCoin.balanceOf(deployer.address);
        console.log(`Deployer's NOVA balance (before script funding): ${ethers.formatEther(deployerNovaBalanceBeforeScript)} NOVA`);


        // 1. Fund NovaCoin (using debugMint if available, or transfer)
        try {
            const novaBalanceBefore = await novaCoin.balanceOf(wallet.address); // Balance of the test user's wallet
            // CRITICAL FIX: Ensure BigInt comparison
            if (novaBalanceBefore < novaAmountToFund / 2n) { // Use 'n' suffix for BigInt literals
                console.log(`Funding ${ethers.formatEther(novaAmountToFund)} NOVA...`);
                // Prefer debugMint if it exists, otherwise use transfer
                if (typeof novaCoin.debugMint === 'function') { // Check if debugMint function exists on the contract instance
                    console.log(`Calling debugMint to ${wallet.address} with ${ethers.formatEther(novaAmountToFund)} NOVA from ${deployer.address}...`);
                    const tx = await novaCoin.debugMint(wallet.address, novaAmountToFund); // Mints directly to wallet.address
                    await tx.wait();
                    console.log(`+ DebugMinted ${ethers.formatEther(novaAmountToFund)} NOVA to ${wallet.name}. Tx: ${tx.hash}`);
                } else {
                    // Fallback to transfer if debugMint is not available (requires deployer to have sufficient balance)
                    console.log(`debugMint not found, attempting transfer from deployer to ${wallet.address}...`);
                    const tx = await novaCoin.transfer(wallet.address, novaAmountToFund); // Transfers from deployer to wallet.address
                    await tx.wait();
                    console.log(`+ Transferred ${ethers.formatEther(novaAmountToFund)} NOVA to ${wallet.name}. Tx: ${tx.hash}`);
                }
            } else {
                console.log(`- ${wallet.name} already has enough NOVA: ${ethers.formatEther(novaBalanceBefore)} NOVA.`);
            }
        } catch (error) {
            console.error(`Error funding NOVA for ${wallet.name}: ${error.message}`);
            // Provide more specific context based on the error
            if (error.message.includes("Ownable: caller is not the owner")) {
                console.error("  -> Action: Deployer must be the contract owner. Verify deployer account is the contract owner on Polygonscan.");
            } else if (error.message.includes("transfer amount exceeds balance") || error.message.includes("insufficient funds")) {
                console.error("  -> Action: Deployer's wallet (0x7c00e...D50) must have sufficient NOVA. Check token holdings on Polygonscan.");
            } else if (error.message.includes("execution reverted")) {
                console.error("  -> Action: Contract's debugMint/transfer logic reverted. Check contract logic on Polygonscan.");
            }
        }

        // 2. Fund MATIC
        try {
            const maticBalanceBefore = await ethers.provider.getBalance(wallet.address);
            // CRITICAL FIX: Ensure BigInt comparison
            if (maticBalanceBefore < maticAmountToFund / 2n) { // Use 'n' suffix for BigInt literals
                console.log(`Funding ${ethers.formatEther(maticAmountToFund)} MATIC...`);
                // CRITICAL FIX: Use ethers.resolveAddress to ensure target is a valid address format for sendTransaction
                // (Note: For plain addresses, resolveAddress sometimes triggers unimplemented ENS lookups with Hardhat's provider)
                // Let's remove resolveAddress for direct address strings here as it caused issues for Recipient MATIC
                const tx = await deployer.sendTransaction({
                    to: wallet.address, // Pass address string directly
                    value: maticAmountToFund,
                });
                await tx.wait();
                console.log(`+ Funded ${wallet.name} with ${ethers.formatEther(maticAmountToFund)} MATIC. Tx: ${tx.hash}`);
            } else {
                console.log(`- ${wallet.name} already has enough MATIC: ${ethers.formatEther(maticBalanceBefore)} MATIC.`);
            }
        } catch (error) {
            console.error(`Error funding MATIC for ${wallet.name}: ${error.message}`);
            if (error.message.includes("insufficient funds")) {
                console.error("  -> Action: Deployer must have enough MATIC to send. Check deployer balance on Polygonscan.");
            } else if (error.message.includes("resolveName")) {
                console.error("  -> Action: resolveName issue. Check address format or re-try.");
            }
        }
    }

    console.log("\n--- Test Wallet Funding Script Complete ---");
}

// REMOVED getImplementationAddress helper function as it's hardcoded in main() now.

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });