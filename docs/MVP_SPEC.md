# MVP Specification

## MVP Name

**LendSignal Credit-Based Lending Vault**

## MVP Objective

Create a working demo where an emerging market business connects a wallet, submits business evidence, receives an updateable onchain Credit Certificate, and gets an automatic working-capital loan payout if the certificate passes the vault policy.

## Demo Flow

1. User connects wallet.
2. User submits business information and mock documents.
3. User completes mock KYC/KYB.
4. LendSignal treats the connected wallet as the business credit identity.
5. LendSignal simulates Confidential AI Attester scoring.
6. LendSignal combines that score with a mock CRS credit bureau score and wallet behavior score.
7. LendSignal stores an updateable Credit Certificate onchain.
8. A lending vault checks certificate status, score, ENS gate and liquidity.
9. If approved, the vault automatically pays out loan tokens.
10. Borrower fees flow into a default insurance fund.
11. If a loan defaults, the default fund reimburses lenders.

## Core Screens

### 1. Business Onboarding

Shows:

- business legal name;
- country or market;
- industry;
- requested loan amount;
- wallet connection;
- mock KYC/KYB status;
- submitted document checklist.

Documents:

- business registration;
- tax identifier or tax record;
- bank statements;
- financial statements;
- invoices or accounts receivable data;
- debt schedule;
- signer authorization.

### 2. Credit Worthiness Score

Shows:

- borrower wallet;
- borrower business profile;
- Confidential AI Attester score;
- CRS credit bureau score;
- wallet behavior score;
- combined Credit Worthiness Score;
- risk tier;
- attestation hash;
- evidence digest;
- ENS gate status.

Formula:

```text
combinedScore =
  confidentialAiScore * 60%
  + crsBureauScore * 25%
  + walletBehaviorScore * 15%
```

Risk tiers:

```text
750-1000: Low Default Risk
600-749: Medium Default Risk
0-599: High Default Risk
```

### 3. Credit Certificate

Shows:

- certificate id;
- business wallet;
- combined score;
- risk tier;
- status;
- attestation hash;
- evidence digest;
- issued date;
- expiration date;
- last updated date.

Certificate lifecycle:

```text
pending
active
expired
updated
revoked
defaulted
```

### 4. Borrowing-Lending Vault

Shows:

- vault liquidity;
- requested loan amount;
- approval threshold;
- ENS gate;
- loan status;
- automatic payout transaction.

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

Demo comparison:

Without LendSignal:

```text
Max loan: $5,000
Collateral required: 150%
Rate: 14%
```

With LendSignal:

```text
Max loan: $25,000
Collateral required: score-based / reduced collateral
Rate: 9%
```

### 5. Insurance Default Fund

Shows:

- LP deposits;
- borrower fees;
- covered loan exposure;
- LP rewards;
- default claim;
- lender reimbursement status.

## Scores

### Credit Worthiness Score

Scale: `0-1000`.

Signals:

- mock Confidential AI Attester score;
- mock CRS credit bureau score;
- optional onchain wallet sanity checks.

Risk tiers:

```text
750-1000: Low Default Risk
600-749: Medium Default Risk
0-599: High Default Risk
```

## MVP Data Sources

### Real or Mocked for Hackathon

- mock borrower profiles;
- mock Confidential AI Attester output;
- mock CRS bureau output;
- mock wallet behavior score;
- mock KYC/KYB status;
- mock business documents;
- ENS gate status;
- vault liquidity;
- borrower fee;
- default event.

## Confidential Processing Simulation

The production vision uses Chainlink CRE, Confidential Compute and a Confidential AI Attester.

For the hackathon MVP, simulate the workflow with deterministic mock outputs:

1. User selects or uploads sample borrower documents.
2. App displays encrypted ingestion into a confidential workflow.
3. App derives financial metrics from sample JSON.
4. App produces a signed AI attestation.
5. App anchors or displays the attestation hash.
6. App publishes only score, risk tier, summary and proof metadata.

If the team has an API key, the app can call the Chainlink Confidential AI Attester demo:

```text
POST /v1/inference
GET /v1/inference/:id
```

The API accepts a prompt and up to 10 resources. Resources can be uploaded files or HTTP(S) URLs. The result is asynchronous, so the app must poll until the request is `completed` or `failed`.

## Post-MVP Ideas

- ERC-8004-style wallet identity and reputation.
- Curator marketplace.
- Real credit bureau integration.
- Real confidential compute workflow.
- Advanced risk model.

## AI Credit Attestation Format

```json
{
  "id": "att_ai_001",
  "subject": "0xWallet",
  "subjectType": "business_wallet",
  "signalType": "creditworthiness_score",
  "score": 840,
  "riskTier": "low_default_risk",
  "summary": "Sensitive borrower data analyzed confidentially. Fraud risk low and financial profile supports working-capital lending.",
  "metrics": {
    "currentRatio": 1.8,
    "quickRatio": 1.3,
    "dscr": 1.6,
    "cashBurnMonths": 9,
    "revenueGrowth": "positive"
  },
  "evidenceHash": "0x...",
  "computeProof": "0x...",
  "issuedAt": "2026-06-13T00:00:00Z",
  "expiresAt": "2026-07-13T00:00:00Z",
  "attester": "chainlink_confidential_ai_attester_mock",
  "signature": "0x..."
}
```

## Credit Certificate Format

```json
{
  "certificateId": "cert_001",
  "borrower": "0xWallet",
  "confidentialAiScore": 840,
  "crsBureauScore": 782,
  "walletBehaviorScore": 760,
  "combinedScore": 816,
  "riskTier": "low_default_risk",
  "status": "active",
  "attestationHash": "0x...",
  "evidenceDigest": "0x...",
  "ensGatePassed": true,
  "issuedAt": "2026-06-13T00:00:00Z",
  "lastUpdatedAt": "2026-06-13T00:00:00Z",
  "expiresAt": "2026-07-13T00:00:00Z"
}
```

## What We Should Not Build in MVP

- real credit bureau integration;
- real bank connection;
- full KYC/KYB;
- production scoring model;
- regulated lending product;
- storage of private raw documents;
- real confidential compute integration;
- full ERC-8004 reputation layer;
- full curator network.

## MVP Deliverables

- public frontend;
- business onboarding page;
- Credit Worthiness Score page;
- Credit Certificate page or panel;
- demo lending vault page;
- default fund mock page or panel;
- Credit Certificate Registry contract;
- lending vault contract or fork;
- default fund contract;
- ENS gate mock or lookup;
- architecture diagram;
- README.
