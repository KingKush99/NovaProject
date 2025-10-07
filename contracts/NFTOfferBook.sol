// Filename: contracts/NFTOfferBook.sol (FINAL CORRECTED VERSION)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

abstract contract Initializable {
    bool private _initialized;
    bool private _initializing;
    modifier initializer() {
        bool isTopLevel = !_initializing;
        require(isTopLevel ? !_initialized : _initializing, "Initializable: contract is already initialized");
        _initialized = true;
        if (isTopLevel) { _initializing = true; }
        _;
        if (isTopLevel) { _initializing = false; }
    }
    modifier onlyInitializing() { require(_initializing, "Initializable: contract is not initializing"); _; }
    function _disableInitializers() internal virtual { require(!_initializing, "Initializable: contract is initializing"); if (_initialized) { return; } _initialized = true; }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts/utils/Context.sol ---
abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}
//--- End of Imported File ---

//--- Start of Imported File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol ---
abstract contract OwnableUpgradeable is Initializable, Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    // Corrected: __Ownable_init takes NO arguments in OZ 4.9.0+
    function __Ownable_init() internal onlyInitializing { _transferOwnership(_msgSender()); } 
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() { require(owner() == _msgSender(), "Ownable: caller is not the owner"); _; }
    function transferOwnership(address newOwner) public virtual onlyOwner { _transferOwnership(newOwner); }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner; _owner = newOwner; emit OwnershipTransferred(oldOwner, newOwner);
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
contract NFTOfferBook is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    INovaRegistry public novaRegistry;
    struct Offer { address offeror; uint256 amount; }
    mapping(address => mapping(uint256 => Offer)) public offers;
    event OfferMade(address indexed offeror, address indexed nftAddress, uint256 indexed tokenId, uint256 amount);
    event OfferAccepted(address indexed seller, address indexed nftAddress, uint256 indexed tokenId);
    event OfferCancelled(address indexed offeror, address indexed nftAddress, uint256 indexed tokenId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }

    // Corrected: __Ownable_init takes NO arguments in OZ 4.9.0+
    function initialize(address initialOwner, address registryAddress) public initializer {
        __Ownable_init(); 
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();
        novaRegistry = INovaRegistry(registryAddress);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function makeOffer(address _nftAddress, uint256 _tokenId, uint256 _amount) external nonReentrant {
        require(offers[_nftAddress][_tokenId].offeror == address(0), "Offer: Exists.");
        address novaCoinAddress = novaRegistry.getContractAddress(keccak256(abi.encodePacked("NOVA_COIN")));
        IERC20(novaCoinAddress).transferFrom(msg.sender, address(this), _amount);
        offers[_nftAddress][_tokenId] = Offer(msg.sender, _amount);
        emit OfferMade(msg.sender, _nftAddress, _tokenId, _amount);
    }

    function cancelOffer(address _nftAddress, uint256 _tokenId) external nonReentrant {
        Offer memory offer = offers[_nftAddress][_tokenId];
        require(offer.offeror == msg.sender, "Offer: Not owner.");
        delete offers[_nftAddress][_tokenId];
        address novaCoinAddress = novaRegistry.getContractAddress(keccak256(abi.encodePacked("NOVA_COIN")));
        IERC20(novaCoinAddress).transfer(msg.sender, offer.amount);
        emit OfferCancelled(msg.sender, _nftAddress, _tokenId);
    }

    function acceptOffer(address _nftAddress, uint256 _tokenId) external nonReentrant {
        Offer memory offer = offers[_nftAddress][_tokenId];
        require(offer.offeror != address(0), "Offer: DNE.");
        require(IERC721(_nftAddress).ownerOf(_tokenId) == msg.sender, "Offer: Not NFT owner."); // Assumes msg.sender is the seller
        delete offers[_nftAddress][_tokenId];
        IERC721(_nftAddress).transferFrom(msg.sender, offer.offeror, _tokenId);
        address novaCoinAddress = novaRegistry.getContractAddress(keccak256(abi.encodePacked("NOVA_COIN")));
        IERC20(novaCoinAddress).transfer(msg.sender, offer.amount);
        emit OfferAccepted(msg.sender, _nftAddress, _tokenId);
    }
}