// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm, VM_ADDRESS} from "./utils/Vm.sol";
import {CreditCertificateRegistry} from "../src/CreditCertificateRegistry.sol";
import {CreditTypes} from "../src/libraries/CreditTypes.sol";

/// @notice Tests for the credit/score registry (contract #1).
/// @dev Self-contained: uses a vendored minimal cheatcode interface and `require`-based
///      assertions, so `forge test` runs with no forge-std submodule.
contract CreditCertificateRegistryTest {
    Vm internal constant vm = Vm(VM_ADDRESS);

    CreditCertificateRegistry internal registry;
    address internal issuer = address(0xA11CE);
    address internal borrower = address(0xB0B);

    function setUp() public {
        vm.warp(1_000_000); // a sane non-zero start timestamp
        registry = new CreditCertificateRegistry(issuer);
    }

    // --- helpers ---

    function _inputs(uint256 ai, uint256 bureau) internal view returns (CreditTypes.ScoreInputs memory) {
        return CreditTypes.ScoreInputs({
            confidentialAiScore: ai,
            bureauScore: bureau,
            attestationHash: keccak256("attestation"),
            bureauReportHash: keccak256("bureau-report"),
            evidenceDigest: keccak256("evidence"),
            expiresAt: block.timestamp + 30 days
        });
    }

    function _eq(uint256 a, uint256 b, string memory m) internal pure {
        require(a == b, m);
    }

    // --- tests ---

    function test_IssueComputesCombinedScoreAndTier() public {
        vm.prank(issuer);
        registry.issueCertificate(borrower, _inputs(840, 782));

        // (840*7000 + 782*3000) / 10000 = 822
        CreditTypes.CreditCertificate memory cert = registry.getCertificate(borrower);
        _eq(cert.confidentialAiScore, 840, "ai stored");
        _eq(cert.bureauScore, 782, "bureau stored");
        _eq(cert.combinedScore, 822, "combined score");
        _eq(uint256(cert.riskTier), uint256(CreditTypes.RiskTier.Low), "risk tier low");
        _eq(uint256(cert.status), uint256(CreditTypes.Status.Active), "active");
        _eq(cert.version, 1, "version 1");
        require(registry.isEligible(borrower), "eligible");
        _eq(registry.borrowersCount(), 1, "borrower indexed");
    }

    function test_WeakBorrowerIsHighRiskAndIneligible() public {
        vm.prank(issuer);
        registry.issueCertificate(borrower, _inputs(500, 560));
        // (500*7000 + 560*3000) / 10000 = 518 -> High
        _eq(registry.combinedScoreOf(borrower), 518, "combined");
        _eq(uint256(registry.riskTierOf(borrower)), uint256(CreditTypes.RiskTier.High), "high");
        require(!registry.isEligible(borrower), "not eligible");
    }

    function test_OnlyIssuerCanIssue() public {
        vm.expectRevert(CreditCertificateRegistry.NotIssuer.selector);
        registry.issueCertificate(borrower, _inputs(840, 782)); // msg.sender = this, not issuer
    }

    function test_RejectsScoreAboveMax() public {
        vm.prank(issuer);
        vm.expectRevert(CreditCertificateRegistry.InvalidScore.selector);
        registry.issueCertificate(borrower, _inputs(1001, 782));
    }

    function test_RejectsPastExpiry() public {
        CreditTypes.ScoreInputs memory inp = _inputs(840, 782);
        inp.expiresAt = block.timestamp; // not strictly in the future
        vm.prank(issuer);
        vm.expectRevert(CreditCertificateRegistry.InvalidExpiry.selector);
        registry.issueCertificate(borrower, inp);
    }

    function test_DoubleIssueReverts() public {
        vm.prank(issuer);
        registry.issueCertificate(borrower, _inputs(840, 782));
        vm.prank(issuer);
        vm.expectRevert(CreditCertificateRegistry.AlreadyCertified.selector);
        registry.issueCertificate(borrower, _inputs(840, 782));
    }

    function test_UpdateBumpsVersionAndRescores() public {
        vm.prank(issuer);
        registry.issueCertificate(borrower, _inputs(840, 782));

        vm.prank(issuer);
        registry.updateCertificate(borrower, _inputs(600, 600));
        // (600*7000 + 600*3000)/10000 = 600 -> Medium
        CreditTypes.CreditCertificate memory cert = registry.getCertificate(borrower);
        _eq(cert.combinedScore, 600, "rescored");
        _eq(uint256(cert.riskTier), uint256(CreditTypes.RiskTier.Medium), "medium");
        _eq(cert.version, 2, "version bumped");
        _eq(registry.borrowersCount(), 1, "no duplicate index");
    }

    function test_RevokeMakesIneligible() public {
        vm.prank(issuer);
        registry.issueCertificate(borrower, _inputs(840, 782));
        vm.prank(issuer);
        registry.revokeCertificate(borrower);
        require(!registry.isEligible(borrower), "revoked not eligible");
        _eq(uint256(registry.statusOf(borrower)), uint256(CreditTypes.Status.Revoked), "revoked");
    }

    function test_ExpiryMakesIneligible() public {
        vm.prank(issuer);
        registry.issueCertificate(borrower, _inputs(840, 782));
        vm.warp(block.timestamp + 31 days);
        require(!registry.isEligible(borrower), "expired not eligible");
        _eq(uint256(registry.statusOf(borrower)), uint256(CreditTypes.Status.Expired), "expired");
    }

    function test_WeightsMustSumTo10k() public {
        // registry owner is this test contract (the deployer).
        vm.expectRevert(CreditCertificateRegistry.InvalidWeights.selector);
        registry.setWeights(7000, 2000); // sums to 9000
    }
}
