# LendSignal Wireframes

## Product Navigation

LendSignal should feel like a focused workflow, not a landing page.

Primary navigation:

```text
Onboarding -> Credit Review -> Certificate -> Borrow -> Liquidity -> Default Fund
```

Secondary views:

```text
ENS Records
Sponsor Demo
Transactions
```

## Global Layout

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ LendSignal                         Wallet: 0x12...89  Network: Base Sepolia │
├────────────────────────────────────────────────────────────────────────────┤
│ Onboarding | Credit Review | Certificate | Borrow | Liquidity | Default Fund│
├────────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│ Page content                                                                │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

Header requirements:

- show connected wallet;
- show network;
- show active borrower ENS name if available;
- show certificate status badge once issued.

## Screen 1: Business Onboarding

Goal: collect the minimum business data needed to identify the borrower and prepare scoring.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Business Onboarding                                                        │
│ Connect your business wallet and submit the information used for scoring.  │
├──────────────────────────────────────┬─────────────────────────────────────┤
│ Business Profile                     │ Identity                            │
│                                      │                                     │
│ Legal name       [ Acme Imports LLC ]│ Wallet                              │
│ Country          [ Colombia       v ]│ 0x12...89                           │
│ Industry         [ Trade finance  v ]│                                     │
│ Revenue band     [ $50k-$100k/mo v ] │ ENS name                            │
│ Loan request     [ 25000          ]  │ [ acmeimports.eth              ]    │
│ Purpose          [ Working capital v]│ [ Resolve ENS ]                     │
│                                      │                                     │
│ [ Save Profile ]                     │ ENS status: Passed                  │
├──────────────────────────────────────┴─────────────────────────────────────┤
│ Documents                                                                  │
│ [x] Business registration     [x] Bank statements     [x] Financials       │
│ [x] Tax record                [ ] Invoices            [x] Signer auth      │
│                                                                            │
│ KYC/KYB status: Passed                                                     │
│                                                                            │
│                                      [ Submit For Credit Review ]           │
└────────────────────────────────────────────────────────────────────────────┘
```

States:

- wallet disconnected;
- ENS unresolved;
- missing required business fields;
- KYC/KYB pending;
- ready for credit review.

## Screen 2: Credit Review

Goal: show how LendSignal centralizes offchain and onchain signals before issuing the certificate.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Credit Review                                                              │
│ Private data is processed offchain. Only scores and hashes go onchain.     │
├────────────────────────────────────────────────────────────────────────────┤
│ Signal Sources                                                             │
│                                                                            │
│ ┌──────────────────────┐ ┌──────────────────────┐ ┌──────────────────────┐ │
│ │ Chainlink AI         │ │ CRS Credit Bureau    │ │ Wallet Behavior      │ │
│ │ Status: Completed    │ │ Status: Mocked       │ │ Status: Completed    │ │
│ │ Score: 840           │ │ Score: 782           │ │ Score: 760           │ │
│ │ Fraud risk: Low      │ │ Payment risk: Low    │ │ Risk flags: 0        │ │
│ │ Hash: 0xa1...        │ │ Report hash: 0xb2... │ │ Chains: Base         │ │
│ └──────────────────────┘ └──────────────────────┘ └──────────────────────┘ │
├────────────────────────────────────────────────────────────────────────────┤
│ Score Combiner                                                             │
│                                                                            │
│ Confidential AI 60%    CRS Bureau 25%    Wallet Behavior 15%              │
│                                                                            │
│ Combined Score: 816 / 1000       Risk Tier: Low Default Risk               │
│                                                                            │
│ [ Re-run AI Review ] [ Refresh CRS Mock ] [ Issue Certificate ]            │
└────────────────────────────────────────────────────────────────────────────┘
```

States:

- AI queued;
- AI processing;
- AI failed;
- CRS mock used;
- score below threshold;
- ready to issue certificate.

## Screen 3: Credit Certificate

Goal: make the certificate the central artifact.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Credit Certificate                                                         │
│ This certificate is indexed by wallet and discoverable through ENS records.│
├──────────────────────────────────────┬─────────────────────────────────────┤
│ Certificate                          │ Onchain Status                      │
│                                      │                                     │
│ Certificate ID     cert_001          │ Registry                            │
│ Business wallet    0x12...89         │ 0xRegistry...                       │
│ ENS name           acmeimports.eth   │                                     │
│ Score              816               │ Status                              │
│ Risk tier          Low               │ Active                              │
│ Issued             Jun 13, 2026      │                                     │
│ Expires            Jul 13, 2026      │ Tx                                  │
│                                      │ 0xTxCertificateIssued               │
├──────────────────────────────────────┴─────────────────────────────────────┤
│ Public Proofs                                                              │
│ Attestation hash      0xa1...                                              │
│ Evidence digest       0xb2...                                              │
│ CRS report hash       0xc3...                                              │
│                                                                            │
│ [ Update Certificate ] [ Revoke Certificate ] [ Continue To Borrow ]        │
└────────────────────────────────────────────────────────────────────────────┘
```

Important copy:

```text
Raw documents, KYC/KYB records and CRS reports are never stored onchain.
```

## Screen 4: ENS Records

Goal: prove ENS is part of the credit identity layer, not decorative.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ ENS Credit Identity                                                        │
│ ENS points lenders and agents to the active LendSignal certificate.        │
├────────────────────────────────────────────────────────────────────────────┤
│ ENS Name                                                                   │
│ [ acmeimports.eth                                      ] [ Resolve ]        │
│                                                                            │
│ Resolved address: 0x12...89                                                │
│ Matches borrower wallet: Yes                                               │
├────────────────────────────────────────────────────────────────────────────┤
│ Text Records                                                               │
│                                                                            │
│ lendsignal.certificate   cert_001                                          │
│ lendsignal.attestation   0xa1...                                           │
│ lendsignal.risk-tier     low_default_risk                                  │
│ lendsignal.agent         lendsignal-agent.eth                              │
│                                                                            │
│ Gate result: Passed                                                        │
└────────────────────────────────────────────────────────────────────────────┘
```

States:

- ENS name not found;
- address mismatch;
- missing certificate record;
- attestation mismatch;
- gate passed.

## Screen 5: Borrowing / Lending Vault

Goal: approve and pay out a loan using the certificate.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Borrowing Vault                                                            │
│ Certificate-gated working-capital loan approval.                           │
├──────────────────────────────────────┬─────────────────────────────────────┤
│ Loan Request                         │ Approval Checks                     │
│                                      │                                     │
│ Requested amount   [ 25000 USDC ]    │ [x] Certificate active              │
│ Term               [ 30 days   v ]   │ [x] Certificate not expired         │
│ Borrower wallet    0x12...89         │ [x] Score >= 750                    │
│ ENS name           acmeimports.eth   │ [x] ENS gate passed                 │
│                                      │ [x] Vault liquidity available       │
│                                      │                                     │
│ [ Request Loan ]                     │ Decision: Approved                  │
├──────────────────────────────────────┴─────────────────────────────────────┤
│ Payout                                                                     │
│ Principal: 25,000 USDC                                                     │
│ Origination fee: 750 USDC                                                  │
│ Borrower receives: 24,250 USDC                                             │
│ Default fund receives: 750 USDC                                            │
│                                                                            │
│ [ Approve And Pay Out ]                                                    │
└────────────────────────────────────────────────────────────────────────────┘
```

States:

- no active certificate;
- score too low;
- ENS gate failed;
- insufficient vault liquidity;
- payout completed.

## Screen 6: Liquidity / Uniswap

Goal: show Uniswap API as core value execution for vault/default-fund liquidity.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Liquidity Conversion                                                       │
│ Use Uniswap API to convert LP or borrower tokens into vault assets.        │
├──────────────────────────────────────┬─────────────────────────────────────┤
│ Swap                                 │ Target                              │
│                                      │                                     │
│ From token        [ WETH       v ]   │ Destination                         │
│ Amount            [ 0.10       ]     │ ( ) Lending Vault                   │
│ To token          [ USDC       v ]   │ (x) Default Fund                    │
│                                      │                                     │
│ [ Get Uniswap Quote ]                │ Expected output: 350 USDC           │
│                                      │ Slippage: 0.5%                      │
├──────────────────────────────────────┴─────────────────────────────────────┤
│ Quote / Execution                                                          │
│ Route: WETH -> USDC                                                        │
│ Quote ID: quote_123                                                        │
│ Swap tx: 0xSwapTx...                                                       │
│ Deposit tx: 0xDepositTx...                                                 │
│                                                                            │
│ [ Execute Swap ] [ Deposit To Default Fund ]                               │
└────────────────────────────────────────────────────────────────────────────┘
```

States:

- missing Uniswap API key;
- quote loading;
- approval required;
- swap ready;
- swap submitted;
- deposit completed.

## Screen 7: Default Fund

Goal: show lender protection.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Default Fund                                                               │
│ LP liquidity reimburses lenders when approved borrowers default.           │
├──────────────────────────────────────┬─────────────────────────────────────┤
│ Pool Status                          │ LP Action                           │
│                                      │                                     │
│ Total deposits      50,000 USDC      │ Deposit amount [ 5000 USDC ]        │
│ Borrower fees       750 USDC         │                                     │
│ Covered exposure    25,000 USDC      │ [ Deposit ]                         │
│ Reimbursed claims   0 USDC           │                                     │
│                                      │                                     │
├──────────────────────────────────────┴─────────────────────────────────────┤
│ Default Simulation                                                         │
│ Loan ID: 1                                                                 │
│ Borrower: 0x12...89                                                        │
│ Reimbursement amount: 10,000 USDC                                          │
│                                                                            │
│ [ Mark Default ] [ Reimburse Lender ]                                      │
└────────────────────────────────────────────────────────────────────────────┘
```

States:

- no deposits;
- deposit completed;
- claim pending;
- claim reimbursed;
- insufficient default fund balance.

## Screen 8: Sponsor Demo Dashboard

Goal: make judging easy.

```text
┌────────────────────────────────────────────────────────────────────────────┐
│ Sponsor Demo Dashboard                                                     │
├────────────────────────────────────────────────────────────────────────────┤
│ Chainlink                                                                  │
│ [x] Confidential AI request completed                                      │
│ [x] Attestation hash generated                                             │
│ [x] Certificate issued onchain                                             │
│ Request ID: 0198...                                                        │
│ Tx: 0xCertificateTx...                                                     │
├────────────────────────────────────────────────────────────────────────────┤
│ ENS                                                                        │
│ [x] ENS name resolved dynamically                                          │
│ [x] Text records read                                                      │
│ [x] ENS gate used for lending decision                                     │
├────────────────────────────────────────────────────────────────────────────┤
│ Uniswap                                                                    │
│ [x] Quote requested through API                                            │
│ [x] Swap executed                                                          │
│ [x] Asset deposited into DefaultFund                                       │
│ Tx: 0xSwapTx...                                                            │
├────────────────────────────────────────────────────────────────────────────┤
│ Core Product                                                               │
│ [x] Business onboarded                                                     │
│ [x] Credit Certificate active                                              │
│ [x] Loan paid out                                                          │
│ [x] Default fund reimbursement demo ready                                  │
└────────────────────────────────────────────────────────────────────────────┘
```

## Mobile Priority

Mobile can be simplified to one column:

```text
Header
Step indicator
Primary panel
Secondary details accordion
Action button
Transaction list
```

Do not try to show all sponsor proof at once on mobile. Use collapsible sections.

## Implementation Notes

- Use a stepper at the top of the app to keep the flow understandable.
- Every sponsor integration should produce a visible proof:
  - Chainlink: request id + attestation hash + certificate tx.
  - ENS: resolved address + text records + gate result.
  - Uniswap: quote + swap tx + deposit tx.
- Keep the `Credit Certificate` view as the central screen.
- Avoid showing raw private data after onboarding.
- Prefer status badges over paragraphs.
- Keep all tx hashes copyable.
