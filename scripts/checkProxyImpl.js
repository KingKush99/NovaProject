// scripts/checkProxyImpl.js
require('dotenv').config();
const { ethers } = require("ethers");

const RPC   = process.env.AMOY_RPC_URL;  // must be set in NovaProject/.env
const PROXY = "0xf471af2aFF654A07CD9f55B6cfa22dD019FbaFEf"; // AuctionHouse proxy

// ERC1967 implementation slot
const IMPL_SLOT = "0x360894A13BA1A3210667C828492DB98DCA3E2076CC3735A920A3CA505D382BBC";

async function main() {
  if (!RPC) {
    console.error("AMOY_RPC_URL is missing. Put it in NovaProject/.env");
    process.exit(1);
  }

  const provider = new ethers.JsonRpcProvider(RPC);

  // Read the implementation address from the proxy storage
  let raw;
  if (provider.getStorage) raw = await provider.getStorage(PROXY, IMPL_SLOT);
  else raw = await provider.getStorageAt(PROXY, IMPL_SLOT); // fallback for some ethers builds

  const impl = ethers.getAddress("0x" + raw.slice(-40));
  console.log("Implementation behind proxy:", impl);

  // Try calling novaToken() on the proxy (only exists on the ERC20/NOVA version)
  const iface = new ethers.Interface(["function novaToken() view returns (address)"]);
  const data  = iface.encodeFunctionData("novaToken", []);
  try {
    const ret = await provider.call({ to: PROXY, data });
    const [novaAddr] = iface.decodeFunctionResult("novaToken", ret);
    console.log("novaToken() on proxy ->", novaAddr);
  } catch {
    console.log("novaToken() call failed on proxy -> very likely still the old ETH/MATIC version.");
  }
}

main().catch(console.error);
