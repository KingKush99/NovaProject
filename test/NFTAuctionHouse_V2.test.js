const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTAuctionHouse_V2", function () {
    // We define variables that will be used across our tests
    let owner, seller, bidder, treasury;
    let paymentToken;
    let auctionHouseV2;

    // This `beforeEach` block runs before each "it" test block
    beforeEach(async function () {
        // Get different accounts from Hardhat's local blockchain
        [owner, seller, bidder, treasury] = await ethers.getSigners();

        // --- DEPLOY A MOCK ERC20 TOKEN ---
        // We need a fake token (like your NovaCoin) to use for payments.
        const MockERC20 = await ethers.getContractFactory("MockERC20");
        paymentToken = await MockERC20.deploy("Mock Token", "MTK");

        // Give the bidder some mock tokens to spend
        await paymentToken.transfer(bidder.address, ethers.parseEther("1000"));

        // --- DEPLOY THE V2 AUCTION HOUSE ---
        const NFTAuctionHouse_V2 = await ethers.getContractFactory("NFTAuctionHouse_V2");
        // When deploying, we pass the owner's address and the mock token's address
        auctionHouseV2 = await NFTAuctionHouse_V2.deploy(owner.address, await paymentToken.getAddress());
    });

    // Test Case 1: Check if funds are sent to the treasury on auction end
    it("Should transfer the highest bid to the treasury wallet when endAuction is called", async function () {
        // --- 1. ARRANGE (Setup the test scenario) ---

        // The owner sets the treasury wallet address
        await auctionHouseV2.connect(owner).setTreasuryWallet(treasury.address);

        const auctionId = 1;
        const bidAmount = ethers.parseEther("100"); // 100 mock tokens

        // Create a mock auction in the contract
        await auctionHouseV2.createMockAuction(auctionId, seller.address, bidAmount);

        // The bidder must first approve the auction house contract to spend their tokens
        await paymentToken.connect(bidder).approve(await auctionHouseV2.getAddress(), bidAmount);

        // Get the initial balances of the seller and the treasury
        const initialSellerBalance = await paymentToken.balanceOf(seller.address);
        const initialTreasuryBalance = await paymentToken.balanceOf(treasury.address);

        // --- 2. ACT (Execute the function we want to test) ---

        // For this test, we'll pretend the bidder made the winning bid.
        // In a real scenario, you'd have a 'placeBid' function, but for this test,
        // we just need to ensure the contract can pull the funds.
        // We'll directly transfer the bid from the bidder to the contract to simulate this.
        await paymentToken.connect(bidder).transfer(await auctionHouseV2.getAddress(), bidAmount);

        // Now, call the endAuction function
        await auctionHouseV2.endAuction(auctionId);

        // --- 3. ASSERT (Verify the results are correct) ---

        // Get the final balances
        const finalSellerBalance = await paymentToken.balanceOf(seller.address);
        const finalTreasuryBalance = await paymentToken.balanceOf(treasury.address);

        // Check that the seller's balance DID NOT change
        expect(finalSellerBalance).to.equal(initialSellerBalance);

        // Check that the treasury's balance INCREASED by the bid amount
        expect(finalTreasuryBalance).to.equal(initialTreasuryBalance + bidAmount);
    });

    // Test Case 2: Check that only the owner can set the treasury wallet
    it("Should fail if a non-owner tries to set the treasury wallet", async function() {
        // Expect this transaction to be "reverted" (fail) with a specific error message
        // from OpenZeppelin's Ownable contract.
        await expect(
            auctionHouseV2.connect(seller).setTreasuryWallet(treasury.address)
        ).to.be.revertedWithCustomError(auctionHouseV2, "OwnableUnauthorizedAccount");
    });
});