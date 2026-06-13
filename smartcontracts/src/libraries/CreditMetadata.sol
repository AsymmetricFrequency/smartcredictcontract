// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CreditTypes} from "./CreditTypes.sol";
import {Base64} from "./Base64.sol";
import {Strings} from "./Strings.sol";

/// @title CreditMetadata
/// @notice Builds the fully onchain `tokenURI` (JSON + dynamic SVG) for a soulbound
///         credit certificate. The art reflects the live certificate state.
library CreditMetadata {
    using Strings for uint256;

    function tokenURI(
        CreditTypes.CreditCertificate memory cert,
        address owner,
        uint256 tokenId,
        CreditTypes.Status effectiveStatus
    ) internal pure returns (string memory) {
        string memory tier = _tierName(cert.riskTier);
        string memory color = _tierColor(cert.riskTier);
        string memory status = _statusName(effectiveStatus);
        string memory subject = bytes(cert.ensName).length > 0 ? cert.ensName : _shortAddress(owner);

        string memory image = Base64.encode(bytes(_svg(cert.combinedScore, tier, color, status, subject)));

        string memory json = string.concat(
            '{"name":"LendSignal Credit Certificate #',
            tokenId.toString(),
            '","description":"Soulbound onchain credit certificate by LendSignal. Non-transferable; score and status update over time.",',
            '"image":"data:image/svg+xml;base64,',
            image,
            '","attributes":[',
            '{"trait_type":"Score","value":',
            cert.combinedScore.toString(),
            '},{"trait_type":"Risk Tier","value":"',
            tier,
            '"},{"trait_type":"Status","value":"',
            status,
            '"},{"trait_type":"AI Score","value":',
            cert.confidentialAiScore.toString(),
            '},{"trait_type":"Bureau Score","value":',
            cert.bureauScore.toString(),
            '},{"trait_type":"Expires At","display_type":"date","value":',
            cert.expiresAt.toString(),
            "}",
            _ensAttribute(cert.ensName),
            "]}"
        );

        return string.concat("data:application/json;base64,", Base64.encode(bytes(json)));
    }

    // ---------------------------------------------------------------------
    // SVG
    // ---------------------------------------------------------------------

    function _svg(
        uint256 score,
        string memory tier,
        string memory color,
        string memory status,
        string memory subject
    ) private pure returns (string memory) {
        return string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" viewBox="0 0 350 350">',
            '<rect width="350" height="350" rx="20" fill="#0b1220"/>',
            '<rect x="14" y="14" width="322" height="322" rx="16" fill="none" stroke="',
            color,
            '" stroke-width="2"/>',
            '<text x="28" y="48" fill="#9ca3af" font-family="monospace" font-size="13">LendSignal</text>',
            '<text x="28" y="70" fill="#e5e7eb" font-family="monospace" font-size="16">Credit Certificate</text>',
            '<text x="175" y="172" fill="#ffffff" font-family="monospace" font-size="72" font-weight="bold" text-anchor="middle">',
            score.toString(),
            "</text>",
            '<text x="175" y="200" fill="#9ca3af" font-family="monospace" font-size="14" text-anchor="middle">/ 1000</text>',
            '<rect x="95" y="224" width="160" height="34" rx="17" fill="',
            color,
            '"/>',
            '<text x="175" y="246" fill="#0b1220" font-family="monospace" font-size="14" font-weight="bold" text-anchor="middle">',
            tier,
            "</text>",
            '<text x="28" y="300" fill="#e5e7eb" font-family="monospace" font-size="14">',
            subject,
            "</text>",
            '<text x="28" y="322" fill="#9ca3af" font-family="monospace" font-size="12">Status: ',
            status,
            "</text>",
            "</svg>"
        );
    }

    // ---------------------------------------------------------------------
    // Helpers
    // ---------------------------------------------------------------------

    function _ensAttribute(string memory ensName) private pure returns (string memory) {
        if (bytes(ensName).length == 0) return "";
        return string.concat(',{"trait_type":"ENS","value":"', ensName, '"}');
    }

    function _tierName(CreditTypes.RiskTier tier) private pure returns (string memory) {
        if (tier == CreditTypes.RiskTier.Low) return "LOW RISK";
        if (tier == CreditTypes.RiskTier.Medium) return "MEDIUM RISK";
        return "HIGH RISK";
    }

    function _tierColor(CreditTypes.RiskTier tier) private pure returns (string memory) {
        if (tier == CreditTypes.RiskTier.Low) return "#16a34a";
        if (tier == CreditTypes.RiskTier.Medium) return "#d97706";
        return "#dc2626";
    }

    function _statusName(CreditTypes.Status status) private pure returns (string memory) {
        if (status == CreditTypes.Status.Active) return "ACTIVE";
        if (status == CreditTypes.Status.Expired) return "EXPIRED";
        if (status == CreditTypes.Status.Revoked) return "REVOKED";
        if (status == CreditTypes.Status.Defaulted) return "DEFAULTED";
        if (status == CreditTypes.Status.Pending) return "PENDING";
        return "NONE";
    }

    function _shortAddress(address a) private pure returns (string memory) {
        bytes memory h = _toHexString(a); // "0x" + 40 hex chars
        bytes memory out = new bytes(12); // 0x1234..abcd
        out[0] = h[0];
        out[1] = h[1];
        out[2] = h[2];
        out[3] = h[3];
        out[4] = h[4];
        out[5] = h[5];
        out[6] = ".";
        out[7] = ".";
        out[8] = h[38];
        out[9] = h[39];
        out[10] = h[40];
        out[11] = h[41];
        return string(out);
    }

    function _toHexString(address a) private pure returns (bytes memory) {
        bytes16 hexDigits = "0123456789abcdef";
        bytes20 b = bytes20(a);
        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = hexDigits[uint8(b[i] >> 4)];
            str[3 + i * 2] = hexDigits[uint8(b[i] & 0x0f)];
        }
        return str;
    }
}
