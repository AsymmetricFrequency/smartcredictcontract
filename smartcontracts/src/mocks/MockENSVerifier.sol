// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IENSVerifier} from "../interfaces/IENSVerifier.sol";

/// @title MockENSVerifier
/// @notice Demo ENS gate. Returns true only for explicitly whitelisted
///         (borrower, ensName, attestationHash) combinations.
contract MockENSVerifier is IENSVerifier {
    mapping(bytes32 => bool) public verified;

    function setVerified(address borrower, string calldata ensName, bytes32 attestationHash, bool ok)
        external
    {
        verified[_key(borrower, ensName, attestationHash)] = ok;
    }

    function isVerified(address borrower, string calldata ensName, bytes32 attestationHash)
        external
        view
        override
        returns (bool)
    {
        return verified[_key(borrower, ensName, attestationHash)];
    }

    function _key(address borrower, string calldata ensName, bytes32 attestationHash)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(borrower, ensName, attestationHash));
    }
}
