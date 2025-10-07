// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * UUPS-upgradeable Auction House that uses an ERC20 (NOVA) token for bids/payments.
 * Storage layout stays compatible with the original ETH/MATIC version by APPENDING
 * the new variable `paymentToken` and NOT renaming existing ones.
 */
contract NFTAuctionHouse is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    struct Auction {
        address seller;
        address nftAddress;
        uint256 tokenId;
        uint256 endAt;
        address highestBidder;
        uint256 highestBid;     // in NOVA (ERC20) smallest unit
        bool ended;
    }

    // --- existing storage (DO NOT REORDER/REMOVE) ---
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;

    // --- NEW STORAGE (APPEND ONLY) ---
    IERC20 public paymentToken; // keep this exact name & type for compatibility

    // Events (unchanged)
    event AuctionCreated(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 startingBid,
        uint256 endAt
    );
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 winningBid);
    event PaymentTokenSet(address token);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        auctionCount = 0;
        // OwnableUpgradeable already sets owner in __Ownable_init(initialOwner)
    }

    // One-time initializer for V2 to set the NOVA token
    function initializeV2(address nova) external reinitializer(2) {
        require(address(paymentToken) == address(0), "Already initialized");
        require(nova != address(0), "Invalid token");
        paymentToken = IERC20(nova);
        emit PaymentTokenSet(nova);
    }

    // Optional alias so frontends can call novaToken()
    function novaToken() public view returns (IERC20) {
        return paymentToken;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * Create a new auction. Seller transfers the NFT to this contract.
     * @param _nftAddress ERC721 contract
     * @param _tokenId token id
     * @param _startingBid starting bid in NOVA (wei units of your ERC20)
     * @param _duration seconds until end
     */
    function createAuction(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _startingBid,
        uint256 _duration
    ) external nonReentrant {
        require(_nftAddress != address(0), "Invalid NFT");
        require(_duration > 0, "Duration required");

        // Pull the NFT into escrow
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);

        uint256 currentAuctionId = auctionCount++;
        auctions[currentAuctionId] = Auction({
            seller: msg.sender,
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            endAt: block.timestamp + _duration,
            highestBidder: address(0),
            highestBid: _startingBid,
            ended: false
        });

        emit AuctionCreated(
            currentAuctionId,
            msg.sender,
            _nftAddress,
            _tokenId,
            _startingBid,
            block.timestamp + _duration
        );
    }

    /**
     * Place a higher bid in NOVA. Caller must approve this contract for `amount` beforehand.
     * NOTE: signature changed vs. ETH version to include `amount`.
     */
    function placeBid(uint256 auctionId, uint256 amount) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.nftAddress != address(0), "Auction: Not found");
        require(block.timestamp < auction.endAt, "Auction: Ended");
        require(!auction.ended, "Auction: Already settled");
        require(amount > auction.highestBid, "Auction: Bid too low");
        require(address(paymentToken) != address(0), "Token not set");

        // Pull new bid from bidder
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);

        // Refund previous highest bidder (if any)
        if (auction.highestBidder != address(0)) {
            paymentToken.safeTransfer(auction.highestBidder, auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = amount;

        emit BidPlaced(auctionId, msg.sender, amount);
    }

    /**
     * Buy now for current `highestBid` (used as the price). Caller must approve
     * at least `highestBid` and have enough NOVA. No ETH/MATIC is sent.
     */
    function buyNow(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.nftAddress != address(0), "Auction: Not found");
        require(block.timestamp < auction.endAt, "Auction: Ended");
        require(!auction.ended, "Auction: Already settled");
        require(address(paymentToken) != address(0), "Token not set");

        uint256 price = auction.highestBid;
        require(price > 0, "Auction: No price set");

        // Pull funds from buyer
        paymentToken.safeTransferFrom(msg.sender, address(this), price);

        // Refund prior highest bidder if different from buyer
        if (auction.highestBidder != address(0) && auction.highestBidder != msg.sender) {
            paymentToken.safeTransfer(auction.highestBidder, auction.highestBid);
        }

        // Finalize
        auction.highestBidder = msg.sender;
        auction.ended = true;

        // Transfer NFT to buyer
        IERC721(auction.nftAddress).transferFrom(address(this), msg.sender, auction.tokenId);

        // Payout seller
        paymentToken.safeTransfer(auction.seller, price);

        emit AuctionEnded(auctionId, msg.sender, price);
    }

    /**
     * Settle after end time. If there is a highest bidder, deliver NFT and pay seller;
     * otherwise, return NFT to seller.
     */
    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(auction.nftAddress != address(0), "Auction: Not found");
        require(block.timestamp >= auction.endAt, "Auction: Not ended yet");
        require(!auction.ended, "Auction: Already settled");
        require(address(paymentToken) != address(0), "Token not set");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            IERC721(auction.nftAddress).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            paymentToken.safeTransfer(auction.seller, auction.highestBid);
            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            IERC721(auction.nftAddress).transferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
}
