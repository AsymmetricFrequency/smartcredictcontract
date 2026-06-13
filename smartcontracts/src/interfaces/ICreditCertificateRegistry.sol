// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CreditTypes} from "../libraries/CreditTypes.sol";

/// @title ICreditCertificateRegistry
/// @notice Read/write surface of the LendSignal credit certificate registry.
/// @dev This is the contract that *centralizes* the offchain credit signals
///      (Chainlink Confidential AI + offchain CRS bureau) and *defines the per-user
///      score* onchain. Lending contracts consume it through `isEligible`.
interface ICreditCertificateRegistry {
    // --- Events ---

    event CertificateIssued(
        address indexed borrower,
        uint256 combinedScore,
        CreditTypes.RiskTier riskTier,
        bytes32 attestationHash,
        uint256 expiresAt
    );

    event CertificateUpdated(
        address indexed borrower, uint256 combinedScore, CreditTypes.RiskTier riskTier, uint64 version
    );

    event CertificateRevoked(address indexed borrower);

    event CertificateDefaulted(address indexed borrower);

    /// @notice Emitted on every write so indexers can reconstruct score composition.
    event SignalsRecorded(
        address indexed borrower,
        uint256 confidentialAiScore,
        uint256 bureauScore,
        bytes32 attestationHash,
        bytes32 bureauReportHash,
        bytes32 evidenceDigest
    );

    event IssuerUpdated(address indexed previousIssuer, address indexed newIssuer);
    event WeightsUpdated(uint16 aiWeightBps, uint16 bureauWeightBps);
    event MinEligibleScoreUpdated(uint256 previous, uint256 current);

    // --- Writes (issuer-gated) ---

    function issueCertificate(address borrower, CreditTypes.ScoreInputs calldata inputs) external;

    function updateCertificate(address borrower, CreditTypes.ScoreInputs calldata inputs) external;

    function revokeCertificate(address borrower) external;

    function markDefault(address borrower) external;

    // --- Views ---

    function getCertificate(address borrower)
        external
        view
        returns (CreditTypes.CreditCertificate memory);

    function statusOf(address borrower) external view returns (CreditTypes.Status);

    function combinedScoreOf(address borrower) external view returns (uint256);

    function riskTierOf(address borrower) external view returns (CreditTypes.RiskTier);

    function isEligible(address borrower) external view returns (bool);

    function borrowersCount() external view returns (uint256);
}
