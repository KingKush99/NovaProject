// app.js

console.log("STARTING app.js...");

const express = require('express');
const config = require('./config');
const { ethers } = require('ethers');
const path = require('path');

// --- Load deployed contract addresses and ABIs ---
const contractAddresses = config.contractAddresses;
const getAbi = config.getAbi;

// --- Ethers provider + wallet for signing transactions ---
const provider = new ethers.providers.JsonRpcProvider(config.amoyRpcUrl);
const wallet = new ethers.Wallet(config.adminPrivateKey, provider);

console.log("Ethers provider and wallet ready.");

// --- Instantiate contracts globally, if needed ---
const contracts = {};
for (const [name, address] of Object.entries(contractAddresses)) {
  try {
    const abi = getAbi(name);
    contracts[name] = new ethers.Contract(address, abi, wallet);
    console.log(`Loaded contract ${name} at ${address}`);
  } catch (err) {
    console.warn(`Could not load contract or ABI for: ${name}`, err.message);
  }
}

// --- Express app setup ---
const app = express();
app.use(express.json());
console.log("Set up JSON middleware");

// --- User routes ---
console.log("About to load user routes...");
const userRoutes = require('./src/routes/user');
app.use('/api/users', userRoutes);
console.log("Loaded user routes");

// --- NFT routes ---
console.log("About to load nft routes...");
const nftRoutes = require('./src/routes/nft');
app.use('/api/nfts', nftRoutes);
console.log("Loaded nft routes");

// --- Root route ---
app.get('/', (req, res) => {
  res.send('CamAppServer is running.');
});
console.log("Set up root route");

// --- Start server ---
const port = config.port || 9019;
app.listen(port, () => {
  console.log(`✅ Server started on http://localhost:${port}`);
});
