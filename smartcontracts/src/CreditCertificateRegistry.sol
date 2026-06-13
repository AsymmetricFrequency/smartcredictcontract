// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CreditTypes} from "./libraries/CreditTypes.sol";
import {ICreditCertificateRegistry} from "./interfaces/ICreditCertificateRegistry.sol";
import {IENSRegistry, IAddrResolver, ITextResolver} from "./interfaces/IENS.sol";

/// @title CreditCertificateRegistry
/// @author LendSignal
/// @notice Onchain hub that CENTRALIZES the offchain credit signals, DEFINES the per-user
///         credit score, and GATES eligibility on an ENS identity.
///
///         PHASE 1 score sources (wallet-behavior signal intentionally out of scope):
///           1. Chainlink Confidential AI Attester score  ("CRI" signal)
///           2. Offchain CRS credit-risk bureau score
///
///         Information enters here through a single trusted path:
///
///           LendSignal backend / Chainlink CRE workflow
///             -> Confidential AI Attester score  (Chainlink)
///             -> CRS / credit-risk bureau score   (offchain)
///                 => issuer signs issueCertificate(borrower, ScoreInputs)
///                 => issuer signs linkEns(borrower, name, namehash)
///                     => this contract blends scores into `combinedScore`, derives the
///                        risk tier, stores an updateable certificate, and verifies the
///                        ENS identity onchain.
///
///         ENS gate (real, not cosmetic): a certificate is only eligible if its linked ENS
///         name resolves back to the borrower wallet (and, optionally, the
///         `lendsignal.attestation` text record matches the certificate's attestation
///         hash). Lending contracts just read `isEligible`.
contract CreditCertificateRegistry is ICreditCertificateRegistry {
    // ---------------------------------------------------------------------
    // Roles
    // ---------------------------------------------------------------------

    /// @notice Admin: rotates the issuer, tunes the score policy and the ENS gate.
    address public owner;

    /// @notice The only address allowed to write certificates (backend / CRE signer).
    address public issuer;

    // ---------------------------------------------------------------------
    // Score policy ("structure of the score") — tunable by owner
    // ---------------------------------------------------------------------

    uint16 public aiWeightBps = 7000; // 70% Confidential AI (Chainlink)
    uint16 public bureauWeightBps = 3000; // 30% CRS bureau (offchain)

    /// @notice Minimum combined score for a certificate to be considered eligible.
    uint256 public minEligibleScore = 750;

    // ---------------------------------------------------------------------
    // ENS gate config — tunable by owner
    // ---------------------------------------------------------------------

    /// @notice ENS registry used for onchain resolution. address(0) = not configured.
    IENSRegistry public ens;

    /// @notice When true, `isEligible` also requires `isEnsVerified`.
    bool public ensGateEnabled;

    /// @notice When true, ENS verification also checks the `lendsignal.attestation` record.
    bool public requireAttestationRecord;

    /// @notice The ENS text-record key carrying the attestation hash.
    string public constant ATTESTATION_KEY = "lendsignal.attestation";

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
    error NotCertified(); // update/revoke/linkEns on a missing certificate
    error InvalidEnsNode(); // ensNode is zero

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
            ensName: "",
            ensNode: bytes32(0),
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
    /// @dev Preserves the existing ENS link; only the score/evidence/lifecycle are rewritten.
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
    function linkEns(address borrower, string calldata ensName, bytes32 ensNode)
        external
        onlyIssuer
    {
        if (ensNode == bytes32(0)) revert InvalidEnsNode();
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status == CreditTypes.Status.None) revert NotCertified();
        cert.ensName = ensName;
        cert.ensNode = ensNode;
        cert.lastUpdatedAt = block.timestamp;
        emit EnsLinked(borrower, ensName, ensNode);
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
    function markDefault(address borrower) external onlyIssuer {
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status == CreditTypes.Status.None) revert NotCertified();
        cert.status = CreditTypes.Status.Defaulted;
        cert.lastUpdatedAt = block.timestamp;
        emit CertificateDefaulted(borrower);
    }

    // ---------------------------------------------------------------------
    // Views — credit
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
    /// @dev The lending gate: active, unexpired, score above the floor, risk tier Medium or
    ///      Low, and (when the ENS gate is enabled) a verified ENS identity.
    function isEligible(address borrower) external view returns (bool) {
        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        if (cert.status != CreditTypes.Status.Active) return false;
        if (block.timestamp >= cert.expiresAt) return false;
        if (cert.combinedScore < minEligibleScore) return false;
        if (cert.riskTier == CreditTypes.RiskTier.High) return false;
        if (ensGateEnabled && !_ensOk(borrower)) return false;
        return true;
    }

    // ---------------------------------------------------------------------
    // Views — ENS
    // ---------------------------------------------------------------------

    /// @inheritdoc ICreditCertificateRegistry
    function isEnsVerified(address borrower) external view returns (bool) {
        return _ensOk(borrower);
    }

    /// @inheritdoc ICreditCertificateRegistry
    /// @dev The `lendsignal.attestation` text record must equal the 0x-prefixed lowercase
    ///      hex of the certificate's attestation hash.
    function attestationRecord(bytes32 hash) public pure returns (string memory) {
        return _toHexString(hash);
    }

    // ---------------------------------------------------------------------
    // Views — enumeration
    // ---------------------------------------------------------------------

    /// @inheritdoc ICreditCertificateRegistry
    function borrowersCount() external view returns (uint256) {
        return _borrowers.length;
    }

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

    function setEnsRegistry(address ensRegistry) external onlyOwner {
        ens = IENSRegistry(ensRegistry);
        emit EnsRegistryUpdated(ensRegistry);
    }

    function setEnsGateEnabled(bool enabled) external onlyOwner {
        ensGateEnabled = enabled;
        emit EnsGateUpdated(enabled, requireAttestationRecord);
    }

    function setRequireAttestationRecord(bool required) external onlyOwner {
        requireAttestationRecord = required;
        emit EnsGateUpdated(ensGateEnabled, required);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ---------------------------------------------------------------------
    // Internal — scoring
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

    // ---------------------------------------------------------------------
    // Internal — ENS resolution (the gate)
    // ---------------------------------------------------------------------

    /// @dev Resolves the certificate's ENS name onchain and checks it points to the
    ///      borrower. If `ens` is not configured, ENS verification is treated as a pass
    ///      (so the gate can be flipped on only once a registry is wired). External calls
    ///      are wrapped in try/catch so a missing/incompatible resolver fails closed.
    function _ensOk(address borrower) private view returns (bool) {
        if (address(ens) == address(0)) return true;

        CreditTypes.CreditCertificate storage cert = _certificates[borrower];
        bytes32 node = cert.ensNode;
        if (node == bytes32(0)) return false;

        address resolverAddr = ens.resolver(node);
        if (resolverAddr == address(0)) return false;

        try IAddrResolver(resolverAddr).addr(node) returns (address payable resolved) {
            if (resolved != borrower) return false;
        } catch {
            return false;
        }

        if (requireAttestationRecord) {
            try ITextResolver(resolverAddr).text(node, ATTESTATION_KEY) returns (string memory rec) {
                if (keccak256(bytes(rec)) != keccak256(bytes(_toHexString(cert.attestationHash)))) {
                    return false;
                }
            } catch {
                return false;
            }
        }

        return true;
    }

    /// @dev bytes32 -> "0x"-prefixed lowercase hex string (66 chars).
    function _toHexString(bytes32 value) private pure returns (string memory) {
        bytes16 hexDigits = "0123456789abcdef";
        bytes memory str = new bytes(66);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 32; i++) {
            str[2 + i * 2] = hexDigits[uint8(value[i] >> 4)];
            str[3 + i * 2] = hexDigits[uint8(value[i] & 0x0f)];
        }
        return string(str);
    }
}
