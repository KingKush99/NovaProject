// Filename: send-test-tx.js

const { ethers } = require("ethers");

// Replace with your custodial private key (0x... format)
const PRIVATE_KEY = "6934ccfd698122dc11caac4fd5875786f7cbb2397f331b5a9084cee60b61da6d"; // e.g. "0x0c37f72769097d43aa3bb51a481c0c8627a1ef4552ace753e76f767323a8f7a3"
// Replace with your recipient address (can be your MetaMask or another wallet)
const TO = "0x7c00e73d0c8cD8e036BE4b128d9a2454f3aaeD50"; // e.g. "0xYourMetaMaskAddress"

// Amoy (Polygon) public RPC
const provider = new ethers.providers.JsonRpcProvider("https://rpc-amoy.polygon.technology");

// Create a wallet object from the private key and connect it to the provider
const wallet = new ethers.Wallet(PRIVATE_KEY, provider);

async function main() {
    const tx = await wallet.sendTransaction({
        to: TO,
        value: ethers.utils.parseEther("0.001"), // Send 0.001 POL
        maxPriorityFeePerGas: ethers.utils.parseUnits("30", "gwei"), // Safe value
        maxFeePerGas: ethers.utils.parseUnits("50", "gwei"),         // Safe value
        gasLimit: 21000
    });
    console.log("Sent tx:", tx.hash);
    await tx.wait();
    console.log("Transaction confirmed!");
}

main().catch(console.error);
