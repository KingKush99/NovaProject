// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract NovaProfiles is Initializable, OwnableUpgradeable, UUPSUpgradeable, ERC721Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    // Counter to keep track of the next tokenId to be minted
    CountersUpgradeable.Counter private _tokenIdCounter;

    // Mapping from tokenId to the profile's content hash (e.g., IPFS hash)
    mapping(uint256 => string) public tokenContentHashes;

    // Mapping from username hash to the tokenId
    mapping(bytes32 => uint256) public usernameToTokenId;
    
    // Mapping to check if a username hash has been used, for uniqueness check
    mapping(bytes32 => bool) public usernameTaken;

    event ProfileCreated(address indexed user, uint256 indexed tokenId, string username);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
        __ERC721_init("Nova Profile", "NVP");
        transferOwnership(initialOwner);
    }
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    /**
     * @notice Create a new profile NFT with a unique username and content hash (e.g. IPFS URI).
     * @param _username The desired unique username for the profile.
     * @param _contentHash The content hash or URI for the profile metadata.
     */
    function createProfile(string calldata _username, string calldata _contentHash) external {
        // A user can only own one profile NFT from this contract
        require(balanceOf(msg.sender) == 0, "Profile: User already has a profile.");
        
        bytes32 usernameHash = keccak256(abi.encodePacked(_username));
        require(!usernameTaken[usernameHash], "Profile: Username is taken.");
        
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);
        tokenContentHashes[tokenId] = _contentHash;
        usernameToTokenId[usernameHash] = tokenId;
        usernameTaken[usernameHash] = true;
        
        emit ProfileCreated(msg.sender, tokenId, _username);
    }
}
