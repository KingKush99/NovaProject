// Filename: contracts/Gameplay/CollectorSetManager.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
contract CollectorSetManager is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    struct NFTIdentifier { address contractAddress; uint256 tokenId; }
    mapping(bytes32 => NFTIdentifier[]) public sets;
    mapping(address => mapping(bytes32 => bool)) public completedSets;
    event SetDefined(bytes32 indexed setId);
    event SetCompleted(address indexed user, bytes32 indexed setId);
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function defineSet(bytes32 setId, NFTIdentifier[] calldata requiredNFTs) external onlyOwner {
        require(sets[setId].length == 0, "SetManager: Exists.");
        require(requiredNFTs.length > 0, "SetManager: Empty.");
        sets[setId] = requiredNFTs;
        emit SetDefined(setId);
    }
    function claimSetCompletion(bytes32 setId) external {
        require(!completedSets[msg.sender][setId], "SetManager: Completed.");
        NFTIdentifier[] memory requiredNFTs = sets[setId];
        require(requiredNFTs.length > 0, "SetManager: DNE.");
        for (uint i = 0; i < requiredNFTs.length; i++) {
            require(IERC721(requiredNFTs[i].contractAddress).ownerOf(requiredNFTs[i].tokenId) == msg.sender, "SetManager: Missing NFT.");
        }
        completedSets[msg.sender][setId] = true;
        emit SetCompleted(msg.sender, setId);
    }
}