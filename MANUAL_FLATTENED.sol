// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// --- Start of Flattened Dependencies ---

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;
    event Initialized(uint8 version);
    modifier initializer() {
        _EIP1967_initialize();
        _;
    }
    modifier reinitializer(uint8 version) {
        _EIP1967_reinitialize(version);
        _;
    }
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }
    function _disableInitializers() internal virtual {
        _initialized = type(uint8).max;
        emit Initialized(type(uint8).max);
    }
    function _EIP1967_initialize() private {
        require(!_initializing, "Initializable: contract is already initializing");
        require(_initialized < type(uint8).max, "Initializable: contract is already initialized");
        _initialized = 1;
        _initializing = true;
    }
    function _EIP1967_reinitialize(uint8 version) private {
        require(!_initializing, "Initializable: contract is already initializing");
        require(_initialized < type(uint8).max, "Initializable: contract is already initialized");
        require(version > _initialized, "Initializable: new version must be larger than current version");
        _initialized = version;
        _initializing = true;
    }
    function _getInitializedVersion() internal view returns (uint8) { return _initialized; }
    function _getInitializingVersion() internal view returns (uint8) {
        require(_initializing, "Initializable: contract is not initializing");
        return _initialized;
    }
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}
    function __Context_init_unchained() internal onlyInitializing {}
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
    function _msgData() internal view virtual returns (bytes calldata) { return msg.data; }
    function _contextSuffixLength() internal view virtual returns (uint256) { return 0; }
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }
    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        _transferOwnership(initialOwner);
    }
    function owner() public view virtual returns (address) { return _owner; }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: @openzeppelin/contracts/interfaces/draft-IERC1822.sol
interface IERC1822Proxiable {
    function proxiableUUID() external view returns (bytes32);
}

// File: @openzeppelin/contracts/utils/Address.sol
library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }
    function verifyCallResultFromTarget(address target, bool success, bytes memory returndata, string memory errorMessage) internal view returns (bytes memory) {
        if (success) { return returndata; } else { if (returndata.length > 0) { assembly { let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size) } } else { revert(errorMessage); } }
    }
    function verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
        if (success) { return returndata; } else { if (returndata.length > 0) { assembly { let returndata_size := mload(returndata) revert(add(32, returndata), returndata_size) } } else { revert(errorMessage); } }
    }
}

// File: @openzeppelin/contracts/utils/StorageSlot.sol
library StorageSlot {
    struct AddressSlot { address value; }
    struct BooleanSlot { bool value; }
    struct Bytes32Slot { bytes32 value; }
    struct Uint256Slot { uint256 value; }
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) { assembly { r.slot := slot } }
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) { assembly { r.slot := slot } }
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) { assembly { r.slot := slot } }
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) { assembly { r.slot := slot } }
}

// File: @openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol
library ERC1967Utils {
    // *** ASSEMBLY FIX: Define constants using inline assembly to bypass compiler errors ***
    function _implementationSlot() internal pure returns (bytes32 slot) {
        assembly {
            slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bb
        }
    }

    event Upgraded(address indexed implementation);

    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_implementationSlot()).value;
    }

    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_implementationSlot()).value = newImplementation;
    }

    function upgradeToAndCallUUPS(address newImplementation, bytes memory data, bool forceCall) internal {
        if (getImplementation() == newImplementation) { return; }
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) { Address.functionDelegateCall(newImplementation, data); }
    }
}

// File: @openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol
abstract contract UUPSUpgradeable is Initializable, IERC1822Proxiable {
    function __UUPSUpgradeable_init() internal onlyInitializing {}
    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    function proxiableUUID() external view virtual override returns (bytes32) {
        // *** ASSEMBLY FIX: Define constant using inline assembly ***
        bytes32 slot;
        assembly {
            slot := 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bb4
        }
        return slot;
    }

    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual {
        _authorizeUpgrade(newImplementation);
        ERC1967Utils.upgradeToAndCallUUPS(newImplementation, data, true);
    }

    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// --- End of Flattened Dependencies ---

// File: contracts/NovaRegistry.sol
contract NovaRegistry is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    mapping(bytes32 => address) private _contractAddresses;

    event ContractRegistered(bytes32 indexed key, address indexed contractAddress);
    event ContractUpdated(bytes32 indexed key, address indexed oldAddress, address indexed newAddress);

    function initialize(address initialOwner) public initializer {
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();
    }

    function registerContract(bytes32 key, address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "Registry: Zero address");
        require(_contractAddresses[key] == address(0), "Registry: Key already registered");
        _contractAddresses[key] = contractAddress;
        emit ContractRegistered(key, contractAddress);
    }

    function updateContract(bytes32 key, address newContractAddress) external onlyOwner {
        require(newContractAddress != address(0), "Registry: Zero address");
        address oldAddress = _contractAddresses[key];
        require(oldAddress != address(0), "Registry: Key not found");
        _contractAddresses[key] = newContractAddress;
        emit ContractUpdated(key, oldAddress, newContractAddress);
    }

    function getContractAddress(bytes32 key) external view returns (address) {
        return _contractAddresses[key];
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}