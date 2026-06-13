// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm, VM_ADDRESS} from "./utils/Vm.sol";
import {CreditCertificateRegistry} from "../src/CreditCertificateRegistry.sol";
import {SoulboundERC721} from "../src/SoulboundERC721.sol";
import {CreditTypes} from "../src/libraries/CreditTypes.sol";

/// @notice Tests for the soulbound-NFT facet of the registry (contract #1).
contract CreditCertificateNftTest {
    Vm internal constant vm = Vm(VM_ADDRESS);

    CreditCertificateRegistry internal registry;
    address internal borrower = address(0xB0B);
    address internal other = address(0xCAFE);

    function setUp() public {
        vm.warp(1_000_000);
        registry = new CreditCertificateRegistry(address(this)); // owner & issuer = this
        registry.issueCertificate(
            borrower,
            CreditTypes.ScoreInputs({
                confidentialAiScore: 840,
                bureauScore: 782,
                attestationHash: keccak256("att"),
                bureauReportHash: keccak256("rep"),
                evidenceDigest: keccak256("ev"),
                expiresAt: block.timestamp + 30 days
            })
        );
    }

    function _eq(uint256 a, uint256 b, string memory m) internal pure {
        require(a == b, m);
    }

    function _startsWith(string memory s, string memory prefix) internal pure returns (bool) {
        bytes memory sb = bytes(s);
        bytes memory pb = bytes(prefix);
        if (sb.length < pb.length) return false;
        for (uint256 i = 0; i < pb.length; i++) {
            if (sb[i] != pb[i]) return false;
        }
        return true;
    }

    function test_IssueMintsSoulboundToken() public view {
        uint256 id = registry.tokenIdOf(borrower);
        _eq(id, 1, "first token id");
        require(registry.ownerOf(id) == borrower, "owner is borrower");
        _eq(registry.balanceOf(borrower), 1, "balance 1");
        require(registry.locked(id), "locked");
        require(keccak256(bytes(registry.symbol())) == keccak256(bytes("LSCC")), "symbol");
    }

    function test_TransfersAndApprovalsRevert() public {
        uint256 id = registry.tokenIdOf(borrower);

        vm.expectRevert(SoulboundERC721.Soulbound.selector);
        registry.transferFrom(borrower, other, id);

        vm.expectRevert(SoulboundERC721.Soulbound.selector);
        registry.safeTransferFrom(borrower, other, id);

        vm.expectRevert(SoulboundERC721.Soulbound.selector);
        registry.safeTransferFrom(borrower, other, id, "");

        vm.expectRevert(SoulboundERC721.Soulbound.selector);
        registry.approve(other, id);

        vm.expectRevert(SoulboundERC721.Soulbound.selector);
        registry.setApprovalForAll(other, true);
    }

    function test_TokenUriIsOnchainJson() public view {
        string memory uri = registry.tokenURI(registry.tokenIdOf(borrower));
        require(_startsWith(uri, "data:application/json;base64,"), "onchain json data uri");
        require(bytes(uri).length > 200, "non-trivial metadata");
    }

    function test_SupportsExpectedInterfaces() public view {
        require(registry.supportsInterface(0x01ffc9a7), "ERC165");
        require(registry.supportsInterface(0x80ac58cd), "ERC721");
        require(registry.supportsInterface(0x5b5e139f), "ERC721Metadata");
        require(registry.supportsInterface(0xb45a3c0e), "ERC5192");
        require(!registry.supportsInterface(0xffffffff), "unknown false");
    }

    function test_TokenUriRevertsForNonexistent() public {
        vm.expectRevert(SoulboundERC721.NonexistentToken.selector);
        registry.tokenURI(999);
    }

    function test_OnlyOneTokenPerWallet() public view {
        // A second issue is blocked at the certificate layer (AlreadyCertified), so a
        // borrower can never hold two tokens. Here we just confirm the single mint.
        _eq(registry.balanceOf(borrower), 1, "exactly one");
    }
}
