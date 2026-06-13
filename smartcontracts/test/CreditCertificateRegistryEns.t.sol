// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm, VM_ADDRESS} from "./utils/Vm.sol";
import {CreditCertificateRegistry} from "../src/CreditCertificateRegistry.sol";
import {CreditTypes} from "../src/libraries/CreditTypes.sol";
import {MockENSRegistry} from "../src/mocks/MockENSRegistry.sol";
import {MockPublicResolver} from "../src/mocks/MockPublicResolver.sol";

/// @notice Tests for the onchain ENS gate of the credit registry (contract #1).
contract CreditCertificateRegistryEnsTest {
    Vm internal constant vm = Vm(VM_ADDRESS);

    CreditCertificateRegistry internal registry;
    MockENSRegistry internal ens;
    MockPublicResolver internal resolver;

    address internal borrower = address(0xB0B);
    bytes32 internal node = keccak256(bytes("bob.eth"));
    bytes32 internal constant ATT = keccak256("att");

    function setUp() public {
        vm.warp(1_000_000);
        registry = new CreditCertificateRegistry(address(this)); // owner & issuer = this
        ens = new MockENSRegistry();
        resolver = new MockPublicResolver();

        registry.setEnsRegistry(address(ens));
        registry.setEnsGateEnabled(true);
    }

    function _eq(uint256 a, uint256 b, string memory m) internal pure {
        require(a == b, m);
    }

    function _certify() internal {
        registry.issueCertificate(
            borrower,
            CreditTypes.ScoreInputs({
                confidentialAiScore: 840,
                bureauScore: 782,
                attestationHash: ATT,
                bureauReportHash: keccak256("rep"),
                evidenceDigest: keccak256("ev"),
                expiresAt: block.timestamp + 30 days
            })
        );
    }

    /// Resolver points the name back to the borrower -> verified & eligible.
    function _wireResolution(address resolvesTo) internal {
        registry.linkEns(borrower, "bob.eth", node);
        ens.setResolver(node, address(resolver));
        resolver.setAddr(node, resolvesTo);
    }

    function test_GateOn_NoEnsLinked_NotEligible() public {
        _certify();
        require(!registry.isEnsVerified(borrower), "no node -> not verified");
        require(!registry.isEligible(borrower), "gate blocks");
    }

    function test_GateOn_NoResolver_NotEligible() public {
        _certify();
        registry.linkEns(borrower, "bob.eth", node); // linked, but registry has no resolver set
        require(!registry.isEnsVerified(borrower), "no resolver -> not verified");
        require(!registry.isEligible(borrower), "gate blocks");
    }

    function test_GateOn_ResolvesToBorrower_Eligible() public {
        _certify();
        _wireResolution(borrower);
        require(registry.isEnsVerified(borrower), "verified");
        require(registry.isEligible(borrower), "eligible");
    }

    function test_GateOn_ResolvesToOther_NotEligible() public {
        _certify();
        _wireResolution(address(0xDEAD));
        require(!registry.isEnsVerified(borrower), "wrong addr -> not verified");
        require(!registry.isEligible(borrower), "gate blocks");
    }

    function test_AttestationRecord_RequiredAndMatched() public {
        _certify();
        _wireResolution(borrower);
        registry.setRequireAttestationRecord(true);

        // Without the text record set, verification fails.
        require(!registry.isEnsVerified(borrower), "missing att record -> not verified");

        // Set the exact expected record value -> verification passes.
        resolver.setText(node, registry.ATTESTATION_KEY(), registry.attestationRecord(ATT));
        require(registry.isEnsVerified(borrower), "att record matched");
        require(registry.isEligible(borrower), "eligible");
    }

    function test_GateDisabled_PassesWithoutEns() public {
        _certify();
        // No ENS wired at all, but disabling the gate makes the cert eligible again.
        registry.setEnsGateEnabled(false);
        require(registry.isEligible(borrower), "eligible without ENS when gate off");
    }

    function test_LinkEns_RequiresCertificate() public {
        vm.expectRevert(CreditCertificateRegistry.NotCertified.selector);
        registry.linkEns(borrower, "bob.eth", node);
    }

    function test_LinkEns_RejectsZeroNode() public {
        _certify();
        vm.expectRevert(CreditCertificateRegistry.InvalidEnsNode.selector);
        registry.linkEns(borrower, "bob.eth", bytes32(0));
    }

    function test_AttestationRecord_Format() public view {
        string memory rec = registry.attestationRecord(ATT);
        bytes memory b = bytes(rec);
        _eq(b.length, 66, "0x + 64 hex");
        require(b[0] == "0" && b[1] == "x", "0x prefix");
    }
}
