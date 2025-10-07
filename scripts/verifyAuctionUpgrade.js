// scripts/checkProxyImpl.js
require('dotenv').config();
const { ethers } = require("ethers");

const RPC = process.env.AMOY_RPC_URL;                    // your Alchemy Amoy RPC
const PROXY = "0xf471af2aFF654A07CD9f55B6cfa22dD019FbaFEf"; // AuctionHouse proxy

// ERC1967 implementation slot
const IMPL_SLOT = "0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC";

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC);

  // 1) Read implementation address from the proxy’s storage
  const raw = await provider.getStorage(PROXY, IMPL_SLOT);
  const impl = ethers.getAddress("0x" + raw.slice(26)); // last 20 bytes
  console.log("Implementation behind proxy:", impl);

  // 2) Probe for novaToken() on the PROXY (will succeed only if the upgraded ABI is live)
  const iface = new ethers.Interface(["function novaToken() view returns (address)"]);
  const data = iface.encodeFunctionData("novaToken", []);
  try {
    const ret = await provider.call({ to: PROXY, data });
    const [novaAddr] = iface.decodeFunctionResult("novaToken", ret);
    console.log("novaToken() on proxy ->", novaAddr);
  } catch (e) {
    console.log("novaToken() call failed on proxy -> very likely still ETH version.");
  }
}

main().catch(console.error);
