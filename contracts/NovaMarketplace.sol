// Filename: contracts/NovaMarketplace.sol (FINAL CORRECTED VERSION)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INovaRegistry {
    function getContractAddress(bytes32 key) external view returns (address);
}

contract NovaMarketplace is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    INovaRegistry public novaRegistry;
    struct Listing { address seller; address nftAddress; uint256 tokenId; uint256 price; }
    mapping(uint256 => Listing) public listings;
    uint256 private _listingCount;
    event ItemListed(uint256 indexed listingId, address indexed seller, address indexed nftAddress, uint256 tokenId, uint256 price);
    event ItemSold(uint256 indexed listingId, address indexed buyer, address seller, uint256 price);
    event ListingCancelled(uint256 indexed listingId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    
    // Corrected: initialize now correctly calls __Ownable_init() and __ReentrancyGuard_init() without arguments
    function initialize(address initialOwner, address registryAddress) public initializer {
        __Ownable_init(initialOwner); // Corrected: NO ARGUMENT
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init(); // Corrected: NO ARGUMENT
        novaRegistry = INovaRegistry(registryAddress);
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function listItem(address _nftAddress, uint256 _tokenId, uint256 _price) external nonReentrant {
        require(_price > 0, "Marketplace: Price must be > 0");
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        uint256 listingId = _listingCount++;
        listings[listingId] = Listing(msg.sender, _nftAddress, _tokenId, _price);
        emit ItemListed(listingId, msg.sender, _nftAddress, _tokenId, _price);
    }
    function buyItem(uint256 listingId) external nonReentrant {
        Listing memory item = listings[listingId];
        require(item.seller != address(0), "Marketplace: DNE.");
        address novaCoinAddress = novaRegistry.getContractAddress(keccak256(abi.encodePacked("NOVA_COIN")));
        require(novaCoinAddress != address(0), "Marketplace: NovaCoin not registered.");
        IERC20(novaCoinAddress).transferFrom(msg.sender, item.seller, item.price);
        IERC721(item.nftAddress).transferFrom(address(this), msg.sender, item.tokenId);
        delete listings[listingId];
        emit ItemSold(listingId, msg.sender, item.seller, item.price);
    }
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing memory item = listings[listingId];
        require(item.seller == msg.sender, "Marketplace: Not seller.");
        delete listings[listingId];
        IERC721(item.nftAddress).transferFrom(address(this), msg.sender, item.tokenId);
        emit ListingCancelled(listingId);
    }
}