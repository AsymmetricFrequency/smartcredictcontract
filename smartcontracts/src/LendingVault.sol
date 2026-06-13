// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "./interfaces/IERC20.sol";
import {ICreditCertificateRegistry} from "./interfaces/ICreditCertificateRegistry.sol";

/// @title LendingVault
/// @author LendSignal
/// @notice Contract #2: holds LP liquidity and issues undercollateralized working-capital
///         loans, gated by the credit score AND ENS identity in
///         CreditCertificateRegistry (contract #1).
///
///         Lifecycle of a loan:
///           requestLoan        borrower opens a request (must be `isEligible`)
///           approveAndPayout   keeper re-checks the gate, transfers funds
///           repay              borrower returns principal + fee (fee -> protection reserve)
///           markDefault        keeper flags a default; the reserve reimburses the LP pool
///
///         The credit + ENS gate lives entirely in the registry's `isEligible`, so this
///         contract has a single integration point and no ENS logic of its own. A built-in
///         protection `reserve` (funded by origination fees and/or `fundReserve`) absorbs
///         defaults, so the default-fund role lives inside this single contract instead of
///         a third one.
contract LendingVault {
    // ---------------------------------------------------------------------
    // Wiring & roles
    // ---------------------------------------------------------------------

    address public owner;
    IERC20 public immutable asset; // loan asset, e.g. USDC
    ICreditCertificateRegistry public immutable registry; // contract #1 (credit + ENS gate)

    // ---------------------------------------------------------------------
    // Policy (owner-tunable)
    // ---------------------------------------------------------------------

    uint256 public originationFeeBps = 300; // 3% of principal, charged at repayment
    uint256 public maxLoanPerBorrower; // 0 = unlimited
    uint32 public maxDurationDays = 90;

    uint256 internal constant BPS = 10_000;
    uint256 internal constant MAX_FEE_BPS = 5_000; // hard cap: 50%

    // ---------------------------------------------------------------------
    // Accounting (all amounts in `asset` units)
    // ---------------------------------------------------------------------

    uint256 public liquidity; // LP capital currently available to lend
    uint256 public reserve; // default-protection pool
    uint256 public totalOutstanding; // principal currently lent out
    mapping(address => uint256) public lpBalances;

    // ---------------------------------------------------------------------
    // Loans
    // ---------------------------------------------------------------------

    enum LoanStatus {
        None,
        Requested,
        Active,
        Repaid,
        Defaulted,
        Cancelled
    }

    struct Loan {
        uint256 id;
        address borrower;
        uint256 principal;
        uint256 fee;
        uint256 requestedAt;
        uint256 dueAt;
        string ensName;
        LoanStatus status;
    }

    uint256 public nextLoanId = 1;
    mapping(uint256 => Loan) public loans;
    /// @notice One open (requested or active) loan per borrower at a time. 0 = none.
    mapping(address => uint256) public openLoanOf;

    // ---------------------------------------------------------------------
    // Errors
    // ---------------------------------------------------------------------

    error NotOwner();
    error ZeroAddress();
    error ZeroAmount();
    error NotEligible();
    error InsufficientLiquidity();
    error InsufficientLpBalance();
    error InvalidDuration();
    error ExceedsMaxLoan();
    error HasOpenLoan();
    error InvalidLoanState();
    error NotBorrower();
    error InvalidPolicy();
    error TransferFailed();

    // ---------------------------------------------------------------------
    // Events
    // ---------------------------------------------------------------------

    event Deposited(address indexed lp, uint256 amount);
    event Withdrawn(address indexed lp, uint256 amount);
    event ReserveFunded(address indexed from, uint256 amount);
    event LoanRequested(uint256 indexed loanId, address indexed borrower, uint256 principal, string ensName);
    event LoanPaidOut(uint256 indexed loanId, address indexed borrower, uint256 principal, uint256 fee);
    event LoanRepaid(uint256 indexed loanId, address indexed borrower, uint256 principal, uint256 fee);
    event LoanDefaulted(uint256 indexed loanId, address indexed borrower, uint256 principal, uint256 reimbursed);
    event LoanCancelled(uint256 indexed loanId, address indexed borrower);
    event PolicyUpdated(uint256 originationFeeBps, uint256 maxLoanPerBorrower, uint32 maxDurationDays);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(IERC20 _asset, ICreditCertificateRegistry _registry) {
        if (address(_asset) == address(0) || address(_registry) == address(0)) revert ZeroAddress();
        asset = _asset;
        registry = _registry;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // ---------------------------------------------------------------------
    // Liquidity (LPs)
    // ---------------------------------------------------------------------

    /// @notice LP supplies `asset` liquidity to the vault.
    function deposit(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _pull(msg.sender, amount);
        liquidity += amount;
        lpBalances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice LP withdraws supplied liquidity (subject to availability).
    function withdraw(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        if (amount > lpBalances[msg.sender]) revert InsufficientLpBalance();
        if (amount > liquidity) revert InsufficientLiquidity();
        lpBalances[msg.sender] -= amount;
        liquidity -= amount;
        _push(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Pre-fund the default-protection reserve (e.g. for the demo).
    function fundReserve(uint256 amount) external {
        if (amount == 0) revert ZeroAmount();
        _pull(msg.sender, amount);
        reserve += amount;
        emit ReserveFunded(msg.sender, amount);
    }

    // ---------------------------------------------------------------------
    // Borrowing
    // ---------------------------------------------------------------------

    /// @notice Borrower opens a loan request. Requires an eligible credit certificate.
    function requestLoan(uint256 amount, uint32 durationDays, string calldata ensName)
        external
        returns (uint256 loanId)
    {
        if (amount == 0) revert ZeroAmount();
        if (durationDays == 0 || durationDays > maxDurationDays) revert InvalidDuration();
        if (maxLoanPerBorrower != 0 && amount > maxLoanPerBorrower) revert ExceedsMaxLoan();
        if (openLoanOf[msg.sender] != 0) revert HasOpenLoan();
        if (!registry.isEligible(msg.sender)) revert NotEligible();

        loanId = nextLoanId++;
        loans[loanId] = Loan({
            id: loanId,
            borrower: msg.sender,
            principal: amount,
            fee: 0,
            requestedAt: block.timestamp,
            dueAt: block.timestamp + uint256(durationDays) * 1 days,
            ensName: ensName,
            status: LoanStatus.Requested
        });
        openLoanOf[msg.sender] = loanId;
        emit LoanRequested(loanId, msg.sender, amount, ensName);
    }

    /// @notice Borrower (or owner) cancels an unfunded request, freeing the borrower slot.
    function cancelLoan(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        if (loan.status != LoanStatus.Requested) revert InvalidLoanState();
        if (msg.sender != loan.borrower && msg.sender != owner) revert NotBorrower();
        loan.status = LoanStatus.Cancelled;
        openLoanOf[loan.borrower] = 0;
        emit LoanCancelled(loanId, loan.borrower);
    }

    /// @notice Re-check the registry gate (credit score + ENS) and pay out the loan.
    /// @dev Keeper/owner triggered. Eligibility is re-read at payout time so a revoked,
    ///      expired or ENS-unverified certificate between request and payout blocks the
    ///      transfer.
    function approveAndPayout(uint256 loanId) external onlyOwner {
        Loan storage loan = loans[loanId];
        if (loan.status != LoanStatus.Requested) revert InvalidLoanState();
        if (!registry.isEligible(loan.borrower)) revert NotEligible();
        if (loan.principal > liquidity) revert InsufficientLiquidity();

        uint256 fee = (loan.principal * originationFeeBps) / BPS;
        loan.fee = fee;
        loan.status = LoanStatus.Active;

        liquidity -= loan.principal;
        totalOutstanding += loan.principal;

        _push(loan.borrower, loan.principal);
        emit LoanPaidOut(loanId, loan.borrower, loan.principal, fee);
    }

    /// @notice Borrower repays principal + fee. Principal returns to the LP pool; the fee
    ///         strengthens the protection reserve.
    function repay(uint256 loanId) external {
        Loan storage loan = loans[loanId];
        if (loan.status != LoanStatus.Active) revert InvalidLoanState();
        if (msg.sender != loan.borrower) revert NotBorrower();

        uint256 principal = loan.principal;
        uint256 fee = loan.fee;

        _pull(msg.sender, principal + fee);
        loan.status = LoanStatus.Repaid;

        liquidity += principal;
        reserve += fee;
        totalOutstanding -= principal;
        openLoanOf[loan.borrower] = 0;

        emit LoanRepaid(loanId, loan.borrower, principal, fee);
    }

    /// @notice Flag an active loan as defaulted and reimburse the LP pool from the reserve.
    /// @dev Reimbursement is an internal reserve -> liquidity move (funds are already held
    ///      by the vault), capped at the available reserve. Owner may separately call
    ///      registry.markDefault to reflect the default on the borrower's certificate.
    function markDefault(uint256 loanId) external onlyOwner {
        Loan storage loan = loans[loanId];
        if (loan.status != LoanStatus.Active) revert InvalidLoanState();
        loan.status = LoanStatus.Defaulted;
        totalOutstanding -= loan.principal;
        openLoanOf[loan.borrower] = 0;

        uint256 coverage = loan.principal <= reserve ? loan.principal : reserve;
        if (coverage > 0) {
            reserve -= coverage;
            liquidity += coverage;
        }
        emit LoanDefaulted(loanId, loan.borrower, loan.principal, coverage);
    }

    // ---------------------------------------------------------------------
    // Views
    // ---------------------------------------------------------------------

    function getLoan(uint256 loanId) external view returns (Loan memory) {
        return loans[loanId];
    }

    /// @notice True if the borrower could be approved right now (credit gate only).
    function isApprovable(address borrower) external view returns (bool) {
        return registry.isEligible(borrower);
    }

    // ---------------------------------------------------------------------
    // Admin
    // ---------------------------------------------------------------------

    function setPolicy(uint256 _originationFeeBps, uint256 _maxLoanPerBorrower, uint32 _maxDurationDays)
        external
        onlyOwner
    {
        if (_originationFeeBps > MAX_FEE_BPS || _maxDurationDays == 0) revert InvalidPolicy();
        originationFeeBps = _originationFeeBps;
        maxLoanPerBorrower = _maxLoanPerBorrower;
        maxDurationDays = _maxDurationDays;
        emit PolicyUpdated(_originationFeeBps, _maxLoanPerBorrower, _maxDurationDays);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // ---------------------------------------------------------------------
    // Internal token helpers
    // ---------------------------------------------------------------------

    function _pull(address from, uint256 amount) private {
        if (!asset.transferFrom(from, address(this), amount)) revert TransferFailed();
    }

    function _push(address to, uint256 amount) private {
        if (!asset.transfer(to, amount)) revert TransferFailed();
    }
}
