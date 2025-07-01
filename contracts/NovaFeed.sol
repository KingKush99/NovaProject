// Filename: contracts/AppIntegrations/NovaFeed.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
contract NovaFeed is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    enum PostCategory { General, Announcement, SecurityAlert }
    struct FeedItem { PostCategory category; string contentHash; uint256 timestamp; }
    mapping(uint256 => FeedItem) public feedItems;
    uint256 private _postCount;
    event ItemPosted(uint256 indexed postId, PostCategory category);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() { _disableInitializers(); }
    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    function getPostCount() external view returns (uint256) { return _postCount; }
    function postItem(PostCategory category, string calldata contentHash) external onlyOwner {
        uint256 postId = _postCount++;
        feedItems[postId] = FeedItem(category, contentHash, block.timestamp);
        emit ItemPosted(postId, category);
    }
}