// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title CreditTypes
/// @notice Shared types for the LendSignal onchain credit layer.
/// @dev This library is the canonical description of *what information enters the chain*
///      and *how the per-user score is structured*.
///
///      PHASE 1 score sources (wallet-behavior signal intentionally OUT of scope for now):
///        1. Chainlink Confidential AI Attester   (the "CRI" signal)
///        2. Offchain credit-risk bureau (CRS)    (the offchain signal)
///
///      Privacy boundary (see docs/ARCHITECTURE.md): raw documents, KYC/KYB records and
///      full bureau reports NEVER go onchain. Only the normalized component scores, the
///      derived combined score, the risk band and content hashes/digests are published.
library CreditTypes {
    // ---------------------------------------------------------------------
    // Enums
    // ---------------------------------------------------------------------

    /// @notice Default-risk band of a certified business wallet.
    /// @dev Enum order is load-bearing: a HIGHER value means LOWER default risk.
    ///      Maps 1:1 to the offchain strings in docs/DATA_MODEL.md:
    ///        High   (0) -> "high_default_risk"   (score    0-599)
    ///        Medium (1) -> "medium_default_risk" (score  600-749)
    ///        Low    (2) -> "low_default_risk"    (score 750-1000)
    enum RiskTier {
        High,
        Medium,
        Low
    }

    /// @notice Lifecycle status of a credit certificate.
    /// @dev `None` is the default for an address that was never certified.
    enum Status {
        None,
        Pending,
        Active,
        Expired,
        Revoked,
        Defaulted
    }

    // ---------------------------------------------------------------------
    // Input payload — "how information enters"
    // ---------------------------------------------------------------------

    /// @notice Canonical INPUT payload produced offchain by the LendSignal pipeline.
    /// @dev This struct is the single entry point for credit information. It is filled by
    ///      the Score Combiner / Chainlink CRE workflow and passed into
    ///      CreditCertificateRegistry.issueCertificate / updateCertificate.
    ///
    ///      Source of each field:
    ///        confidentialAiScore -> Chainlink Confidential AI Attester (0..1000)
    ///        bureauScore         -> offchain CRS credit-risk bureau     (0..1000)
    ///        attestationHash     -> keccak/sha digest of the attester output JSON
    ///        bureauReportHash    -> digest of the raw CRS report (kept offchain)
    ///        evidenceDigest      -> digest over the document/resource set
    struct ScoreInputs {
        uint256 confidentialAiScore;
        uint256 bureauScore;
        bytes32 attestationHash;
        bytes32 bureauReportHash;
        bytes32 evidenceDigest;
        uint256 expiresAt;
    }

    // ---------------------------------------------------------------------
    // Stored record
    // ---------------------------------------------------------------------

    /// @notice The stored, updateable onchain credit certificate for a business wallet.
    /// @dev Keeps the component scores so the composition of `combinedScore` is fully
    ///      transparent and auditable onchain, not just the final number.
    struct CreditCertificate {
        // --- centralized component signals ---
        uint256 confidentialAiScore; // Chainlink Confidential AI
        uint256 bureauScore; // offchain CRS credit-risk bureau
        // --- derived score ---
        uint256 combinedScore; // = weighted blend of the two components
        RiskTier riskTier; // band derived from combinedScore
        // --- evidence anchors (hashes only) ---
        bytes32 attestationHash;
        bytes32 bureauReportHash;
        bytes32 evidenceDigest;
        // --- ENS identity link (the lending gate) ---
        string ensName; // e.g. "acme-business.eth"
        bytes32 ensNode; // namehash of ensName (precomputed offchain)
        // --- lifecycle ---
        Status status;
        uint256 issuedAt;
        uint256 expiresAt;
        uint256 lastUpdatedAt;
        uint64 version; // bumped on every update
    }

    // ---------------------------------------------------------------------
    // Constants & pure helpers — the onchain "score structure"
    // ---------------------------------------------------------------------

    uint256 internal constant MAX_SCORE = 1000;
    uint256 internal constant BPS_DENOMINATOR = 10_000;
    uint256 internal constant LOW_RISK_FLOOR = 750;
    uint256 internal constant MEDIUM_RISK_FLOOR = 600;

    /// @notice Derive the risk band from a 0..1000 score, matching the docs bands.
    function tierForScore(uint256 score) internal pure returns (RiskTier) {
        if (score >= LOW_RISK_FLOOR) return RiskTier.Low;
        if (score >= MEDIUM_RISK_FLOOR) return RiskTier.Medium;
        return RiskTier.High;
    }

    /// @notice Blend the two component scores into one combined score.
    /// @dev Weights are basis points and MUST sum to 10_000. Phase-1 default policy is
    ///      AI 70% / bureau 30%. Each component is expected in [0, 1000], so the result
    ///      is also in [0, 1000].
    function combineScore(uint256 aiScore, uint256 bureauScore, uint16 aiWeightBps, uint16 bureauWeightBps)
        internal
        pure
        returns (uint256)
    {
        return (aiScore * aiWeightBps + bureauScore * bureauWeightBps) / BPS_DENOMINATOR;
    }
}
