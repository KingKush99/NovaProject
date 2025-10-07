// NovaProject/scripts/deploy_novaprofiles.js
const { ethers, upgrades } = require("hardhat");

async function main() {
    console.log("--- Starting NovaProfiles Standalone Deployment ---");

    const [deployer] = await ethers.getSigners();
    console.log("Deploying with account:", deployer.address);

    const initialOwnerAddress = deployer.address;

    const NovaProfiles = await ethers.getContractFactory("NovaProfiles");
    console.log("Deploying new NovaProfiles contract...");
    const novaProfiles = await upgrades.deployProxy(NovaProfiles, [initialOwnerAddress], {
        initializer: "initialize",
        kind: "uups"
    });
    await novaProfiles.waitForDeployment();
    const novaProfilesAddress = await novaProfiles.getAddress();

    console.log("\n--- DEPLOYMENT COMPLETE ---");
    console.log("New NovaProfiles proxy deployed to:", novaProfilesAddress);
    console.log("\nACTION REQUIRED: Update this address in your deployed_addresses.json and CamAppServer config.");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });