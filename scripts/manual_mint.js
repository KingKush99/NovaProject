// scripts/manual_mint.js (SIMPLIFIED FOR DEDICATED SELLER NETWORK)

const { ethers } = require("hardhat");

async function main() {
  // The address of your deployed NovaProfiles NFT contract
  const novaProfilesAddress = "0x12f4d09be9712C98Fb720dfa001BFb2a793C4DEF";

  // The seller's address will be derived from the network's configured account
  const [seller] = await ethers.getSigners(); // This will now be the seller's wallet from amoySeller network

  console.log(`Using Seller's wallet from 'amoySeller' network: ${seller.address}`);

  // Get an instance of the deployed NovaProfiles contract, connected to the seller's signer
  const NovaProfiles = await ethers.getContractFactory("NovaProfiles", seller);
  const novaProfiles = NovaProfiles.attach(novaProfilesAddress);

  // IMPORTANT: Use a NEW, unique username to avoid "username is taken" error
  const uniqueUsername = `MarketSellerFinal${Date.now()}`; // Ensures uniqueness
  const uniqueIpfsHash = `dummy_ipfs_hash_${Date.now()}`;

  console.log(`Minting a new profile NFT for seller: ${seller.address} with username: ${uniqueUsername}`);

  const tx = await novaProfiles.createProfile(uniqueUsername, uniqueIpfsHash);
  console.log(`Transaction sent with hash: ${tx.hash}`);

  console.log("Waiting for transaction confirmation...");
  await tx.wait(); // Wait for 1 confirmation

  console.log("✅ --- Mint Successful! --- ✅");
  console.log(`Seller ${seller.address} has successfully minted their own profile NFT.`);

  // VERIFY THE TOKEN ID ON-CHAIN
  const nextTokenId = await novaProfiles.callStatic.createProfile(uniqueUsername + "temp", uniqueIpfsHash + "temp");
  console.log(`Newly minted NFT should have Token ID: ${nextTokenId.sub(1).toString()}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });