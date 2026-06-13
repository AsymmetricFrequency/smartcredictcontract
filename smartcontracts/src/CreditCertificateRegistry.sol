// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CreditTypes} from "./libraries/CreditTypes.sol";
import {ICreditCertificateRegistry} from "./interfaces/ICreditCertificateRegistry.sol";

/// @title CreditCertificateRegistry
/// @author LendSignal
/// @notice Onchain hub that CENTRALIZES the offchain credit signals and DEFINES the
///         per-user credit score.
///
///         PHASE 1 sources (wallet-behavior signal intentionally out of scope):
///           1. Chainlink Confidential AI Attester score  ("CRI" signal)
///           2. Offchain CRS credit-risk bureau score
///
///         Information enters here through a single trusted path:
///
///           LendSignal backend / Chainlink CRE workflow
///             -> Confidential AI Attester score  (Chainlink)
///             -> CRS / credit-risk bureau score   (offchain)
///                 => issuer EOA signs issueCertificate(borrower, ScoreInputs)
///                     => this contract blends them into `combinedScore`,
///                        derives the risk tier, and stores an updateable certificate.
///
///         The certificate is then read by the LendingVault (contract #2) and by the
///         frontend / ENS gate. Raw private evidence never touches this contract — only
///         normalized scores and content hashes do.
contract CreditCertificateRegistry is ICreditCertificateRegistry {
    // ---------------------------------------------------------------------
    // Roles
    // ---------------------------------------------------------------------

    /// @notice Admin: can rotate the issuer and tune the score policy.
    address public owner;

    /// @notice The only address allowed to write certificates. This is the LendSignal
    ///         backend signer or the Chainlink CRE workflow forwarder.
    address public issuer;

    // ---------------------------------------------------------------------
    // Score policy ("structure of the score") — tunable by owner
    // ---------------------------------------------------------------------

    uint16 public aiWeightBps = 7000; // 70% Confidential AI (Chainlink)
    uint16 public bureauWeightBps = 3000; // 30% CRS bureau (offchain)

    /// @notice Minimum combined score for a certificate to be considered eligible.
    uint256 public minEligibleScore = 750;

    // ---------------------------------------------------------------------
    // Storage
    // ---------------------------------------------------------------------

    mapping(address => CreditTypes.CreditCertificate) private _certificates;

    /// @notice Enumerable list of every borrower ever certified (demo/frontend helper).
    address[] private _borrowers;
    mapping(address => bool) private _known;

    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------

    error NotOwner();
    error NotIssuer();
    error ZeroAddress();
    error InvalidScore(); // a component score > 1000
    error InvalidExpiry(); // expiresAt not in the future
    error InvalidWeights(); // weights do not sum to 10_000
    error AlreadyCertified(); // issue called on an existing certificate
    error NotCertified(); // update/revoke on a missing certificate

    // ---------------------------------------------------------------------
    // Modifiers
    // ---------------------------------------------------------------------

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyIssuer() {
        if (msg.sender != issuer) revert NotIssuer();
        _;
    }

    // ---------------------------------------------------------------------
    // Construction
    // ---------------------------------------------------------------------

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @param _issuer Address allowed to write certificates (backend / CRE signer).
    constructor(address _issuer) {
        if (_issuer == address(0)) revert ZeroAddress();
        owner = msg.sender;
        issuer = _issuer;
        emit OwnershipTransferred(address(0), msg.sender);
        emit IssuerUpdated(address(0), _issuer);
    }

    // ---------------------------------------------------------------------
    // Writes — the data-entry path (issuer-gated)
    // ---------------------------------------------------------------------

    /// @inheritdoc ICreditCertificateRegistry
    function issueCertificate(address borrower, CreditTypes.ScoreInputs calldata inputs)
        external
        onlyIssuer
    {
        _validate(borrower, inputs);
        if (_certificates[borrower].status != CreditTypes.Status.None) revert AlreadyCertified();

        uint256 combined = _combine(inputs);
        CreditTypes.RiskTier tier = CreditTypes.tierForScore(combined);

        _certificates[borrower] = CreditTypes.CreditCertificate({
            confidentialAiScore: inputs.confidentialAiScore,
            bureauScore: inputs.bureauScore,
            combinedScore: combined,
            riskTier: tier,
            attestationHash: inputs.attestationHash,
            bureauReportHash: inputs.bureauReportHash,
            evidenceDigest: inputs.evidenceDigest,
            status: CreditTypes.Status.Active,
            issuedAt: block.timestamp,
            expiresAt: inputs.expiresAt,
            lastUpdatedAt: block.timestamp,
            version: 1
        });

        if (!_known[borrower]) {
            _known[borrower] = true;
            _borrowers.push(borrower);
        }

        emit SignalsRecorded(
            borrower,
            inputs.confidentialAiScore,
            inputs.bureauScore,
            inputs.attestationHash,
            inputs.bureauReportHash,
            inputs.evidenceDigest
        );
        emit CertificateIssued(borrower, combined, tier, inputs.attestationHash, inputs.expiresAt);
    }

    /// @inheritdoc ICreditCertificateRegistry
    function updateCertificate(address borrower, CreditTypes.ScoreInputs calldata inputs)
        external
        onlyIssuer
    {
        _validate(borrower, inputs);
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status == CreditTypes.Status.None) revert NotCertified();

        uint256 combined = _combine(inputs);
        CreditTypes.RiskTier tier = CreditTypes.tierForScore(combined);

        cert.confidentialAiScore = inputs.confidentialAiScore;
        cert.bureauScore = inputs.bureauScore;
        cert.combinedScore = combined;
        cert.riskTier = tier;
        cert.attestationHash = inputs.attestationHash;
        cert.bureauReportHash = inputs.bureauReportHash;
        cert.evidenceDigest = inputs.evidenceDigest;
        cert.status = CreditTypes.Status.Active; // a fresh update reactivates
        cert.expiresAt = inputs.expiresAt;
        cert.lastUpdatedAt = block.timestamp;
        cert.version += 1;

        emit SignalsRecorded(
            borrower,
            inputs.confidentialAiScore,
            inputs.bureauScore,
            inputs.attestationHash,
            inputs.bureauReportHash,
            inputs.evidenceDigest
        );
        emit CertificateUpdated(borrower, combined, tier, cert.version);
    }

    /// @inheritdoc ICreditCertificateRegistry
    function revokeCertificate(address borrower) external onlyIssuer {
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status == CreditTypes.Status.None) revert NotCertified();
        cert.status = CreditTypes.Status.Revoked;
        cert.lastUpdatedAt = block.timestamp;
        emit CertificateRevoked(borrower);
    }

    /// @inheritdoc ICreditCertificateRegistry
    /// @dev Called by the issuer (or, later, the LendingVault via the issuer role) when a
    ///      loan backed by this certificate defaults.
    function markDefault(address borrower) external onlyIssuer {
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status == CreditTypes.Status.None) revert NotCertified();
        cert.status = CreditTypes.Status.Defaulted;
        cert.lastUpdatedAt = block.timestamp;
        emit CertificateDefaulted(borrower);
    }

    // ---------------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------------

    /// @inheritdoc ICreditCertificateRegistry
    function getCertificate(address borrower)
        external
        view
        returns (CreditTypes.CreditCertificate memory)
    {
        return _certificates[borrower];
    }

    /// @inheritdoc ICreditCertificateRegistry
    /// @dev Returns `Expired` on the fly when a stored-Active certificate is past expiry,
    ///      without needing a write to flip the flag.
    function statusOf(address borrower) public view returns (CreditTypes.Status) {
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status == CreditTypes.Status.Active && block.timestamp >= cert.expiresAt) {
            return CreditTypes.Status.Expired;
        }
        return cert.status;
    }

    /// @inheritdoc ICreditCertificateRegistry
    function combinedScoreOf(address borrower) external view returns (uint256) {
        return _certificates[borrower].combinedScore;
    }

    /// @inheritdoc ICreditCertificateRegistry
    function riskTierOf(address borrower) external view returns (CreditTypes.RiskTier) {
        return _certificates[borrower].riskTier;
    }

    /// @inheritdoc ICreditCertificateRegistry
    /// @dev The lending gate. Eligible iff active, unexpired, score above the floor and
    ///      risk tier Medium or Low.
    function isEligible(address borrower) external view returns (bool) {
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        return cert.status == CreditTypes.Status.Active && block.timestamp < cert.expiresAt
            && cert.combinedScore >= minEligibleScore && cert.riskTier != CreditTypes.RiskTier.High;
    }

    /// @inheritdoc ICreditCertificateRegistry
    function borrowersCount() external view returns (uint256) {
        return _borrowers.length;
    }

    /// @notice Enumerate certified borrowers (demo/frontend helper).
    function borrowerAt(uint256 index) external view returns (address) {
        return _borrowers[index];
    }

    // ---------------------------------------------------------------------
    // Admin
    // ---------------------------------------------------------------------

    function setIssuer(address newIssuer) external onlyOwner {
        if (newIssuer == address(0)) revert ZeroAddress();
        emit IssuerUpdated(issuer, newIssuer);
        issuer = newIssuer;
    }

    /// @notice Update the score weights. They MUST sum to 10_000 bps.
    function setWeights(uint16 _aiWeightBps, uint16 _bureauWeightBps) external onlyOwner {
        if (uint256(_aiWeightBps) + uint256(_bureauWeightBps) != CreditTypes.BPS_DENOMINATOR) {
            revert InvalidWeights();
        }
        aiWeightBps = _aiWeightBps;
        bureauWeightBps = _bureauWeightBps;
        emit WeightsUpdated(_aiWeightBps, _bureauWeightBps);
    }

    function setMinEligibleScore(uint256 newMin) external onlyOwner {
        emit MinEligibleScoreUpdated(minEligibleScore, newMin);
        minEligibleScore = newMin;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ---------------------------------------------------------------------
    // Internal
    // ---------------------------------------------------------------------

    function _validate(address borrower, CreditTypes.ScoreInputs calldata inputs) private view {
        if (borrower == address(0)) revert ZeroAddress();
        if (
            inputs.confidentialAiScore > CreditTypes.MAX_SCORE
                || inputs.bureauScore > CreditTypes.MAX_SCORE
        ) revert InvalidScore();
        if (inputs.expiresAt <= block.timestamp) revert InvalidExpiry();
    }

    function _combine(CreditTypes.ScoreInputs calldata inputs) private view returns (uint256) {
        return CreditTypes.combineScore(
            inputs.confidentialAiScore, inputs.bureauScore, aiWeightBps, bureauWeightBps
        );
    }
}
