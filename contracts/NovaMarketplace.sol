// Filename: contracts/NovaMarketplace.sol
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

//--- Start of Imported File: @openzeppelin/contracts/token/ERC20/IERC20.sol ---
interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts/token/ERC721/IERC721.sol ---
interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}
//--- End of Imported File ---

interface INovaRegistry {
    function getContractAddress(bytes32 key) external view returns (address);
}

//--- The Main Contract Logic ---
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
    function initialize(address initialOwner, address registryAddress) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init(); // This will now work
        __ReentrancyGuard_init();
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