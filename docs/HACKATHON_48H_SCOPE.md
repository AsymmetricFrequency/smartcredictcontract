# 48-Hour Hackathon Scope

## Product

**On-Chain Credit-Based Lending for growth scaling in emerging market businesses.**

The demo proves that a business can turn a wallet into an onchain credit identity and receive a working-capital loan based on an updateable Credit Certificate instead of only collateral.

## What We Build

Build only four connected features:

1. **Business Onboarding**
   - Business connects wallet.
   - Business enters basic company information.
   - Business submits mock documents or selects a preloaded borrower profile.
   - Wallet becomes the business credit identity.

2. **Credit Worthiness Score**
   - Mock Confidential AI Attester result.
   - Mock CRS credit bureau result.
   - Mock onchain wallet behavior score.
   - Combine the signals into one score from `0-1000`.
   - Publish only score, risk tier and attestation hash.

3. **Credit Certificate And Automatic Loan Payout**
   - Store a Credit Certificate for the business wallet.
   - Fork or simulate a collateralized lending flow.
   - Adapt approval logic so score gates borrowing.
   - If borrower passes, vault automatically pays out loan tokens.
   - Loan deployment is gated by an ENS record or mocked ENS status.

4. **Reimburse Lenders For Default Loans**
   - Create a decentralized insurance/default pool.
   - LPs deposit liquidity.
   - Borrower fees fund LP rewards.
   - If a loan defaults, the pool reimburses lenders.

## What We Do Not Build

Do not build these during the 48-hour MVP:

- full ERC-8004 identity and reputation registry;
- full curator marketplace;
- real credit bureau integration;
- real confidential compute production workflow;
- real KYC/KYB;
- complex passport protocol;
- production agent automation;
- full repayment collections system;
- cross-chain support;
- production risk model.

These are future roadmap items.

## Demo Screens

### 1. Business Onboarding

Inputs:

- wallet address;
- mock borrower profile;
- business name;
- market/country;
- requested loan amount;
- mock documents;
- KYC/KYB status.

Output:

```text
Business Wallet: 0xBusiness
Business Profile: Submitted
Documents: 4 uploaded
KYC/KYB: Passed
Wallet Identity: Created
```

### 2. Borrower Credit Score

Inputs:

- business wallet;
- mock borrower profile;
- mock Confidential AI score;
- mock CRS bureau score;
- mock wallet behavior score;
- ENS status.

Output:

```text
Confidential AI Attester Score: 840
CRS Bureau Score: 782
Wallet Behavior Score: 760
Combined Credit Worthiness Score: 816
Risk Tier: Low
ENS Gate: Passed
```

### 3. Credit Certificate

Output:

```text
Certificate ID: cert_001
Business Wallet: 0xBusiness
Score: 816
Risk Tier: Low
Status: Active
Attestation Hash: 0x...
Evidence Digest: 0x...
Expires: 30 days
```

### 4. Borrowing-Lending Vault

Inputs:

- requested loan amount;
- active credit certificate;
- borrower score;
- ENS gate status;
- vault liquidity.

Approval policy:

```text
Approve if:
  certificate = active
  certificate not expired
  score >= 750
  ENS gate = passed
  vault has liquidity

Reject if:
  certificate inactive or expired
  score < 750
  ENS gate = failed
  vault lacks liquidity
```

Payout:

```text
Approved:
  transfer loan tokens to borrower
  create loan record
  charge borrower fee
  route fee to default fund
```

### 5. Insurance Default Fund

Inputs:

- LP deposits;
- borrower fees;
- active loan exposure;
- default event.

Output:

```text
Pool liquidity: $50,000
Covered loans: $25,000
Borrower fees: $750
LP reward APR: simulated
Default claim: reimbursed
```

## Minimal Contracts

### CreditCertificateRegistry

Stores certificate output:

```solidity
struct CreditCertificate {
    uint256 score;
    uint8 riskTier;
    bytes32 attestationHash;
    bytes32 evidenceDigest;
    uint256 expiresAt;
    bool active;
}
```

Needed functions:

```text
issueCertificate(borrower, score, riskTier, attestationHash, evidenceDigest, expiresAt)
updateCertificate(borrower, score, riskTier, attestationHash, evidenceDigest, expiresAt)
revokeCertificate(borrower)
getCertificate(borrower)
```

### LendingVault

Handles deposits and loan payout:

```text
deposit()
requestLoan(amount)
approveAndPayout(borrower, amount)
```

Checks:

- score above threshold;
- certificate active and not expired;
- ENS gate passed;
- liquidity available.

### DefaultFund

Handles lender protection:

```text
deposit()
receiveBorrowerFee()
reimburseDefault(loanId)
```

## Minimal Offchain / Mock Services

### Score Combiner

Combines:

```text
combinedScore =
  confidentialAiScore * 60%
  + crsBureauScore * 25%
  + walletBehaviorScore * 15%
```

Risk tier:

```text
750-1000: Low
600-749: Medium
0-599: High
```

### ENS Gate

For MVP, ENS can be:

- real ENS text lookup if available; or
- mocked as `ensVerified: true`.

The UI should still show:

```text
Loan deployment gated by ENS record
```

### Confidential AI Attester API

For the hackathon, use the Chainlink Confidential AI Attester demo as the integration story or a real API call if the team has a key.

```text
Base URL: https://confidential-ai-dev-preview.cldev.cloud
GET /v1/models
POST /v1/inference
GET /v1/inference/:id
```

Requests are asynchronous:

1. Submit inference.
2. Receive `202 Accepted`.
3. Poll until `completed` or `failed`.
4. Use the output plus resource digests to create the certificate.

## Technologies

- Chainlink CRE concept.
- Chainlink Confidential AI Attester concept.
- Chainlink Agent Skills repo for reference.
- ENS gate.
- Solidity lending vault.
- Solidity default fund.
- Frontend demo.
- `.env` for keys/endpoints.
- MCP / agent skill references as integration story, not core build.

## Recommended 48-Hour Build Order

### Day 1

1. Build frontend shell with three screens.
2. Implement business onboarding mock.
3. Implement mock score combiner.
4. Implement `CreditCertificateRegistry`.
5. Implement `LendingVault` approval and payout.

### Day 2

1. Wire UI to local/testnet contracts.
2. Implement `DefaultFund`.
3. Add ENS gate mock or lookup.
4. Add borrower fee routing.
5. Add default reimbursement demo.
6. Polish demo script and UI.

## Pitch Line

LendSignal turns a business wallet into an updateable onchain credit certificate, enabling undercollateralized working-capital loans through confidential AI verification, credit bureau signals, ENS-gated approval and a decentralized default insurance pool.
