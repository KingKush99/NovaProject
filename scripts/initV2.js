// scripts/initV2.js
require('dotenv').config();
const { ethers } = require('ethers');

const RPC = process.env.AMOY_RPC_URL;
const PK  = process.env.DEPLOYER_PRIVATE_KEY; // proxy owner
const proxy = '0xf471af2aFF654A07CD9f55B6cfa22dD019FbaFEf';
const NOVA  = '0x49fc118e0c9931f8b287292b2e61b571651f01ec';

const abi = ['function initializeV2(address nova)'];

(async () => {
  const provider = new ethers.providers.JsonRpcProvider(RPC);
  const wallet   = new ethers.Wallet(PK, provider);
  const c = new ethers.Contract(proxy, abi, wallet);

  const tx = await c.initializeV2(NOVA);
  console.log('initializeV2 tx:', tx.hash);
  await tx.wait();
  console.log('V2 initialized.');
})();
