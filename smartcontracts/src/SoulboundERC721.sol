// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title SoulboundERC721
/// @notice Minimal, non-transferable ERC-721 (one token per address) implementing the
///         ERC-5192 "locked" interface. Vendored so the project stays dependency-free.
/// @dev Transfers and approvals always revert: a credit certificate must stay bound to the
///      business wallet that earned it. Derived contracts call `_mint` and implement
///      `tokenURI`.
abstract contract SoulboundERC721 {
    string public name;
    string public symbol;

    mapping(uint256 => address) internal _ownerOf;
    /// @notice One certificate token per address; 0 means none.
    mapping(address => uint256) public tokenIdOf;

    uint256 private _nextId;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    /// @notice ERC-5192: emitted once, at mint, since the token is permanently locked.
    event Locked(uint256 tokenId);

    error Soulbound();
    error NonexistentToken();
    error AlreadyMinted();

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // --- Views ---

    function ownerOf(uint256 tokenId) public view returns (address owner) {
        owner = _ownerOf[tokenId];
        if (owner == address(0)) revert NonexistentToken();
    }

    function balanceOf(address owner) external view returns (uint256) {
        return tokenIdOf[owner] == 0 ? 0 : 1;
    }

    /// @notice ERC-5192: every token is permanently locked (soulbound).
    function locked(uint256 tokenId) external view returns (bool) {
        ownerOf(tokenId); // reverts if the token does not exist
        return true;
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory);

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC-165
            || interfaceId == 0x80ac58cd // ERC-721
            || interfaceId == 0x5b5e139f // ERC-721 Metadata
            || interfaceId == 0xb45a3c0e; // ERC-5192 (soulbound)
    }

    // --- Disabled transfer / approval surface (soulbound) ---

    function approve(address, uint256) external pure {
        revert Soulbound();
    }

    function setApprovalForAll(address, bool) external pure {
        revert Soulbound();
    }

    function getApproved(uint256) external pure returns (address) {
        return address(0);
    }

    function isApprovedForAll(address, address) external pure returns (bool) {
        return false;
    }

    function transferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256) external pure {
        revert Soulbound();
    }

    function safeTransferFrom(address, address, uint256, bytes calldata) external pure {
        revert Soulbound();
    }

    // --- Minting (internal) ---

    /// @dev Mints the single soulbound token for `to`. Reverts if `to` already holds one.
    function _mint(address to) internal returns (uint256 tokenId) {
        if (to == address(0)) revert NonexistentToken();
        if (tokenIdOf[to] != 0) revert AlreadyMinted();
        tokenId = ++_nextId; // ids start at 1
        _ownerOf[tokenId] = to;
        tokenIdOf[to] = tokenId;
        emit Transfer(address(0), to, tokenId);
        emit Locked(tokenId);
    }
}
