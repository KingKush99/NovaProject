// =================================================================
//      DEFINITIVE hardhat.config.js - COPY AND PASTE THIS
// =================================================================

require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  
  // --- FIX #1: Correct Solidity Version and viaIR ---
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: true, // Required for complex contracts
    },
  },

  // --- FIX #2: Correct Network Configuration with chainId ---
  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL || "",
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : [],
      chainId: 80002, // CRITICAL: Required for v2 API
    },
    // You can add your polygon_mainnet config here later
  },
  
  // --- FIX #3: Correct Etherscan Configuration for v2 API ---
  etherscan: {
    // The API key is a single string, NOT a nested object
    apiKey: process.env.POLYGONSCAN_API_KEY || "", 

    customChains: [
      {
        network: "amoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com"
        }
      }
    ]
  },
};