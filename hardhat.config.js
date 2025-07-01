// =================================================================
//      DEFINITIVE, FINAL, AND CORRECT hardhat.config.js
// =================================================================

require("dotenv").config(); // Must be at the top
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-verify");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  
  // Correct Solidity version for your contracts
  solidity: {
    version: "0.8.30",
    settings: {
      optimizer: { enabled: true, runs: 200 },
      viaIR: true,
    },
  },

  // Correct network configuration for Amoy
  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL || "",
      accounts: process.env.DEPLOYER_PRIVATE_KEY ? [process.env.DEPLOYER_PRIVATE_KEY] : [],
      chainId: 80002, // Explicitly sets the chainId
    },
  },
  
  // The definitive Etherscan configuration that combines both fixes
  etherscan: {
    apiKey: {
      // The key here, "amoy", MUST exactly match the network name in your customChains array.
      amoy: process.env.POLYGONSCAN_API_KEY || "", 
    },
    customChains: [
      {
        network: "amoy", // This name matches the apiKey object key above.
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com"
        }
      }
    ]
  },
};