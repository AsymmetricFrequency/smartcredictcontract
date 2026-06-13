// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IENSVerifier
/// @notice Optional ENS gate for the lending vault.
/// @dev Confirms that an ENS name resolves to the borrower and that its text records
///      match the borrower's onchain attestation hash. For the hackathon this can be a
///      mock; in production it wraps an offchain ENS resolution proof.
interface IENSVerifier {
    function isVerified(address borrower, string calldata ensName, bytes32 attestationHash)
        external
        view
        returns (bool);
}
