// Filename: contracts/NFTAuctionHouse.sol
// SPDX-License-Identifier: MIT
// This file has been manually flattened to resolve import errors. (Corrected Version)

pragma solidity ^0.8.30;

//--- Start of Imported File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol ---
abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;
    modifier initializer() {
        bool isTopLevel = !_initializing;
        require(isTopLevel ? !_initialized : _initializing, "Initializable: contract is already initialized");
        _initialized = true;
        if (isTopLevel) {
            _initializing = true;
        }
        _;
        if (isTopLevel) {
            _initializing = false;
        }
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized) { return; }
        _initialized = true;
    }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts/utils/Context.sol ---
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol ---
abstract contract OwnableUpgradeable is Initializable, Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init(address initialOwner) internal onlyInitializing { _transferOwnership(initialOwner); }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }
    function transferOwnership(address newOwner) public virtual onlyOwner { _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol ---
abstract contract UUPSUpgradeable is Initializable {
    event Upgraded(address indexed implementation);
    function __UUPSUpgradeable_init() internal onlyInitializing {}
    function _authorizeUpgrade(address newImplementation) internal virtual;
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCall(newImplementation, data);
    }
    function _upgradeToAndCall(address newImplementation, bytes memory data) internal {
        (bool success, ) = newImplementation.delegatecall(data);
        require(success, "UUPS upgrade failed");
        emit Upgraded(newImplementation);
    }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol ---
abstract contract ReentrancyGuardUpgradeable is Initializable {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    function __ReentrancyGuard_init() internal onlyInitializing { _status = _NOT_ENTERED; }
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts/token/ERC721/IERC721.sol ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
//--- End of Imported File ---

// --- Main Contract Logic ---
contract NFTAuctionHouse is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    struct Auction { address seller; address nftAddress; uint256 tokenId; uint256 endAt; address highestBidder; uint256 highestBid; bool ended; }
    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount;
    event AuctionCreated(uint256 indexed auctionId, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 startingBid, uint256 endAt);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address winner, uint256 winningBid);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init(); // This will now work
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function createAuction(address _nftAddress, uint256 _tokenId, uint256 _startingBid, uint256 _duration) external nonReentrant {
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        uint256 auctionId = auctionCount++;
        auctions[auctionId] = Auction(msg.sender, _nftAddress, _tokenId, block.timestamp + _duration, address(0), _startingBid, false);
        emit AuctionCreated(auctionId, msg.sender, _nftAddress, _tokenId, _startingBid, block.timestamp + _duration);
    }

    function placeBid(uint256 auctionId) external payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp < auction.endAt, "Auction: Ended.");
        require(msg.value > auction.highestBid, "Auction: Bid too low.");
        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{value: auction.highestBid}("");
            require(success, "Auction: Refund failed.");
        }
        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionId) external nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(block.timestamp >= auction.endAt, "Auction: Not ended yet.");
        require(!auction.ended, "Auction: Already settled.");
        auction.ended = true;
        if (auction.highestBidder != address(0)) {
            IERC721(auction.nftAddress).transferFrom(address(this), auction.highestBidder, auction.tokenId);
            (bool success, ) = payable(auction.seller).call{value: auction.highestBid}("");
            require(success, "Auction: Payout failed.");
            emit AuctionEnded(auctionId, auction.highestBidder, auction.highestBid);
        } else {
            IERC721(auction.nftAddress).transferFrom(address(this), auction.seller, auction.tokenId);
            emit AuctionEnded(auctionId, address(0), 0);
        }
    }
}