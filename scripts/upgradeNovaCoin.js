const { ethers, upgrades } = require("hardhat");

async function main() {
  // Put the proxy address of your currently deployed contract here!
const proxyAddress = "0x0e9ff5e782C5F980e0194BeaeE26139B9F098db8";
 // e.g. "0x0e9f..."

  // Get the new contract "factory"
  const NovaCoin_ProgrammableSupply = await ethers.getContractFactory("NovaCoin_ProgrammableSupply");

  // Upgrade the contract at proxyAddress
  await upgrades.upgradeProxy(proxyAddress, NovaCoin_ProgrammableSupply);

  console.log("NovaCoin_ProgrammableSupply has been upgraded!");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
