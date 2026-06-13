// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Vm, VM_ADDRESS} from "./utils/Vm.sol";
import {LendingVault} from "../src/LendingVault.sol";
import {CreditCertificateRegistry} from "../src/CreditCertificateRegistry.sol";
import {ICreditCertificateRegistry} from "../src/interfaces/ICreditCertificateRegistry.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";
import {CreditTypes} from "../src/libraries/CreditTypes.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

/// @notice Tests for the lending vault (contract #2) consuming the registry (contract #1).
contract LendingVaultTest {
    Vm internal constant vm = Vm(VM_ADDRESS);

    MockERC20 internal usdc;
    CreditCertificateRegistry internal registry;
    LendingVault internal vault;

    address internal lp = address(this); // this contract acts as the LP
    address internal borrower = address(0xB0B);

    uint256 internal constant UNIT = 1e6; // 6-decimal asset
    uint256 internal constant DEPOSIT = 100_000 * UNIT;
    uint256 internal constant LOAN = 10_000 * UNIT;

    function setUp() public {
        vm.warp(1_000_000);
        usdc = new MockERC20("Mock USD Coin", "mUSDC", 6);
        // issuer = this test contract, so we can issue certificates directly.
        registry = new CreditCertificateRegistry(address(this));
        vault = new LendingVault(IERC20(address(usdc)), registry);

        // LP funds the vault.
        usdc.mint(lp, DEPOSIT);
        usdc.approve(address(vault), type(uint256).max);
        vault.deposit(DEPOSIT);
    }

    function _eq(uint256 a, uint256 b, string memory m) internal pure {
        require(a == b, m);
    }

    function _certify(address who, uint256 ai, uint256 bureau) internal {
        registry.issueCertificate(
            who,
            CreditTypes.ScoreInputs({
                confidentialAiScore: ai,
                bureauScore: bureau,
                attestationHash: keccak256("att"),
                bureauReportHash: keccak256("rep"),
                evidenceDigest: keccak256("ev"),
                expiresAt: block.timestamp + 30 days
            })
        );
    }

    function test_FullLoanLifecycle_RequestPayoutRepay() public {
        _certify(borrower, 840, 782); // eligible (822, Low)

        vm.prank(borrower);
        uint256 loanId = vault.requestLoan(LOAN, 30, "bob.eth");

        vault.approveAndPayout(loanId); // owner = this

        _eq(usdc.balanceOf(borrower), LOAN, "borrower funded");
        _eq(vault.liquidity(), DEPOSIT - LOAN, "liquidity reduced");
        _eq(vault.totalOutstanding(), LOAN, "outstanding tracked");

        uint256 fee = (LOAN * 300) / 10_000; // 3% = 300 USDC
        // Borrower needs principal + fee to repay; top up the fee portion.
        usdc.mint(borrower, fee);
        vm.prank(borrower);
        usdc.approve(address(vault), type(uint256).max);
        vm.prank(borrower);
        vault.repay(loanId);

        _eq(vault.liquidity(), DEPOSIT, "principal returned");
        _eq(vault.reserve(), fee, "fee to reserve");
        _eq(vault.totalOutstanding(), 0, "nothing outstanding");

        LendingVault.Loan memory loan = vault.getLoan(loanId);
        _eq(uint256(loan.status), uint256(LendingVault.LoanStatus.Repaid), "repaid");
    }

    function test_IneligibleBorrowerCannotRequest() public {
        // no certificate for borrower
        vm.prank(borrower);
        vm.expectRevert(LendingVault.NotEligible.selector);
        vault.requestLoan(LOAN, 30, "bob.eth");
    }

    function test_DefaultIsCoveredByReserve() public {
        _certify(borrower, 840, 782);

        // Pre-fund the protection reserve enough to cover the principal.
        usdc.mint(lp, LOAN);
        vault.fundReserve(LOAN);

        vm.prank(borrower);
        uint256 loanId = vault.requestLoan(LOAN, 30, "bob.eth");
        vault.approveAndPayout(loanId);

        uint256 liqBefore = vault.liquidity(); // DEPOSIT - LOAN
        vault.markDefault(loanId);

        _eq(vault.reserve(), 0, "reserve drained by coverage");
        _eq(vault.liquidity(), liqBefore + LOAN, "LP pool reimbursed");
        _eq(vault.totalOutstanding(), 0, "loan no longer outstanding");

        LendingVault.Loan memory loan = vault.getLoan(loanId);
        _eq(uint256(loan.status), uint256(LendingVault.LoanStatus.Defaulted), "defaulted");
    }

    function test_RevokedCertificateBlocksPayout() public {
        _certify(borrower, 840, 782);
        vm.prank(borrower);
        uint256 loanId = vault.requestLoan(LOAN, 30, "bob.eth");

        registry.revokeCertificate(borrower); // issuer = this

        vm.expectRevert(LendingVault.NotEligible.selector);
        vault.approveAndPayout(loanId);
    }

    function test_OneOpenLoanPerBorrower() public {
        _certify(borrower, 840, 782);
        vm.prank(borrower);
        vault.requestLoan(LOAN, 30, "bob.eth");
        vm.prank(borrower);
        vm.expectRevert(LendingVault.HasOpenLoan.selector);
        vault.requestLoan(LOAN, 30, "bob.eth");
    }
}
