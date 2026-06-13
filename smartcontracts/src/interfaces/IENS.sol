// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title ENS interfaces (minimal)
/// @notice Just the slices of the ENS registry and resolver that LendSignal needs to use
///         an ENS name as a real, onchain lending gate.
/// @dev Mainnet ENS registry: 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e
///      (same address on Sepolia/Holesky). A resolver is looked up per name via the
///      registry, then queried for `addr` and text records.

interface IENSRegistry {
    function resolver(bytes32 node) external view returns (address);
    function owner(bytes32 node) external view returns (address);
}

/// @notice EIP-137 address resolution.
interface IAddrResolver {
    function addr(bytes32 node) external view returns (address payable);
}

/// @notice EIP-634 text records.
interface ITextResolver {
    function text(bytes32 node, string calldata key) external view returns (string memory);
}
