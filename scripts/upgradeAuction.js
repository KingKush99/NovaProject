// scripts/upgradeAuction_proper.js
require("dotenv").config();
const { ethers, upgrades } = require("hardhat");

async function main() {
  const PROXY = "0xf471af2aFF654A07CD9f55B6cfa22dD019FbaFEf"; // AuctionHouse proxy
  const NOVA  = process.env.NOVA_TOKEN_ADDRESS || "0x49fc118e0c9931f8b287292b2e61b571651f01ec"; // your NOVA on Amoy

  // This factory must be the **new** AuctionHouse code (ERC20/NOVA version)
  const NewAuction = await ethers.getContractFactory("NFTAuctionHouse");

  // Do the UUPS upgrade
  const upgraded = await upgrades.upgradeProxy(PROXY, NewAuction);
  await upgraded.waitForDeployment();

  const proxyAddr = await upgraded.getAddress();
  const implAddr  = await upgrades.erc1967.getImplementationAddress(proxyAddr);

  console.log("Proxy:", proxyAddr);
  console.log("New implementation:", implAddr);

  // If your new impl needs setting the NOVA token (setter or reinitializer), do it here.
  // Try any of these depending on what you added in the contract:
  if (upgraded.initializeNova) {
    const tx = await upgraded.initializeNova(NOVA);
    await tx.wait();
    console.log("initializeNova(NOVA) called");
  } else if (upgraded.setPaymentToken) {
    const tx = await upgraded.setPaymentToken(NOVA);
    await tx.wait();
    console.log("setPaymentToken(NOVA) called");
  }

  // Read back novaToken() to confirm
  try {
    const nova = await upgraded.novaToken();
    console.log("novaToken():", nova);
  } catch {
    console.log("novaToken() not found – are you sure the new implementation has it?");
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
