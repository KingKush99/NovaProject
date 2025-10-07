require("dotenv").config();
require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("@nomicfoundation/hardhat-verify");

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.30",
        settings: {
          optimizer: { enabled: true, runs: 200 },
          viaIR: true, // IR pipeline – required to avoid the UnimplementedFeatureError
        },
      },
    ],
  },

  // keep paths at the top level (optional, default is ./contracts)
  paths: {
    sources: "./contracts",
  },

  networks: {
    amoy: {
      url: process.env.AMOY_RPC_URL,
      accounts: process.env.DEPLOYER_PRIVATE_KEY
        ? [process.env.DEPLOYER_PRIVATE_KEY]
        : [],
      chainId: 80002,
    },
  },

  etherscan: {
    apiKey: { polygonAmoy: process.env.POLYGONSCAN_API_KEY || "" },
    customChains: [
      {
        network: "polygonAmoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com",
        },
      },
    ],
  },
};
