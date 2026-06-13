// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {ICreditCertificateRegistry} from "./interfaces/ICreditCertificateRegistry.sol";

/// @title LendingVault  (Contract #2 — SKELETON / WORK IN PROGRESS)
/// @notice The second LendSignal contract. It consumes the CreditCertificateRegistry to
///         approve and pay out undercollateralized working-capital loans, and (later)
///         routes borrower fees into a default-protection pool.
/// @dev Intentionally minimal for now. The team agreed to finish the credit/score
///      registry (contract #1) first. This file fixes the integration boundary so the
///      vault can be built out next:
///        - deposit(amount)            : LPs fund the vault
///        - requestLoan(amount, ens)   : borrower opens a loan request
///        - approveAndPayout(loanId)   : gate on registry.isEligible + ENS, then transfer
///        - markDefault(loanId)        : flag a defaulted loan and reimburse from the pool
contract LendingVault {
    IERC20 public immutable asset;
    ICreditCertificateRegistry public immutable registry;
    address public owner;

    /// @notice Origination fee charged on payout, routed to default protection.
    uint256 public originationFeeBps = 300; // 3%

    constructor(IERC20 _asset, ICreditCertificateRegistry _registry) {
        asset = _asset;
        registry = _registry;
        owner = msg.sender;
    }

    /// @notice Preview whether a borrower would pass the credit gate, read straight from
    ///         the registry. This is the single integration point with contract #1.
    function isApprovable(address borrower) external view returns (bool) {
        return registry.isEligible(borrower);
    }

    // TODO(next): deposit / requestLoan / approveAndPayout / markDefault + default pool.
}
