# Credit Certification Flow

## Core Idea

LendSignal creates an onchain credit certification for a business wallet.

The business connects to the web app, submits business information and documents, completes KYC/KYB-style verification, and connects the wallet that will represent the business onchain.

From that moment, the wallet becomes the business credit identity.

LendSignal uses:

- user-supplied business information;
- uploaded business documents;
- KYC/KYB checks;
- onchain wallet behavior;
- Chainlink Confidential AI Attester output;
- optional 3rd party credit bureau signal;
- ENS gate or metadata pointer.

The result is a **Credit Certificate** that can be updated over time as the business behaves onchain.

## Product Flow

### 1. Business Onboarding

The business enters:

- legal business name;
- country or market;
- business type;
- industry;
- monthly revenue band;
- requested credit amount;
- requested credit purpose;
- contact and operator information.

The business connects a wallet.

This wallet becomes the onchain identifier used by lending pools, borrowing vaults, liquidity services and future agents.

### 2. Document And KYC/KYB Intake

The app requests business documentation:

- business registration;
- business license;
- tax identifier or tax record;
- bank statements;
- financial statements;
- invoices or accounts receivable data;
- accounts payable data;
- debt schedule;
- operator identity or signer authorization.

For the hackathon, these can be mock files or preloaded sample borrower profiles.

### 3. Confidential AI Processing

LendSignal sends a prompt and optional resources to the Chainlink Confidential AI Attester demo API.

The demo API:

- runs inference asynchronously;
- accepts uploaded files or fetched URLs as resources;
- preprocesses documents when needed;
- runs inside an AWS Nitro Enclave;
- returns a model output;
- returns resource digests and metadata for verification.

Important hackathon API details:

```text
Base URL: https://confidential-ai-dev-preview.cldev.cloud
Auth: Authorization: Bearer <api-key>

List models:
GET /v1/models

Submit inference:
POST /v1/inference

Poll result:
GET /v1/inference/:id
```

Supported models:

```text
gemma4
qwen3.6
```

Requests are asynchronous:

1. Submit request.
2. Receive `202 Accepted`.
3. Poll until `completed` or `failed`.
4. Read the `output`, resource digests and metadata.

### 4. Attester Prompt

The prompt should ask the attester to return structured credit evidence.

Example:

```text
You are evaluating a business borrower for an onchain working-capital loan.

Analyze the provided business documents and return only JSON with:
- business_verified: boolean
- document_authenticity: low | medium | high
- fraud_risk: low | medium | high
- cashflow_strength: low | medium | high
- debt_capacity: low | medium | high
- creditworthiness_score: number from 0 to 1000
- risk_tier: low_default_risk | medium_default_risk | high_default_risk
- reasoning_summary: short explanation
- missing_information: array

Do not expose raw private document content.
```

### 5. Score Combination

LendSignal combines:

- Confidential AI Attester score;
- 3rd party credit bureau score or mock bureau score;
- onchain wallet behavior.

For the hackathon:

```text
combinedScore =
  confidentialAiScore * 70%
  + bureauScore * 20%
  + onchainBehaviorScore * 10%
```

Risk tier:

```text
750-1000: Low Default Risk
600-749: Medium Default Risk
0-599: High Default Risk
```

### 6. Credit Certificate

The Credit Certificate is the public/onchain representation of the business credit state.

It should expose:

- business wallet;
- certificate id;
- combined score;
- risk tier;
- certificate status;
- attestation hash;
- evidence/resource digest;
- ENS pointer or gate;
- issued timestamp;
- expiration timestamp;
- last update timestamp.

It should not expose:

- raw documents;
- full KYC/KYB records;
- bank statements;
- tax records;
- private invoices;
- personal identity documents.

Example:

```json
{
  "certificateId": "cert_001",
  "businessWallet": "0xBusiness",
  "combinedScore": 816,
  "riskTier": "low_default_risk",
  "status": "active",
  "attestationHash": "0x...",
  "evidenceDigest": "0x...",
  "ensName": "acme-business.eth",
  "issuedAt": "2026-06-13T00:00:00Z",
  "expiresAt": "2026-07-13T00:00:00Z",
  "lastUpdatedAt": "2026-06-13T00:00:00Z"
}
```

## Certificate Lifecycle

The certificate is not static.

It can change over time based on:

- new financial documents;
- new KYC/KYB checks;
- repayment behavior;
- defaults;
- wallet activity;
- updated credit bureau data;
- new Chainlink Confidential AI Attester result.

Lifecycle states:

```text
pending
active
expired
updated
revoked
defaulted
```

## Onchain Usage

Lending pools, borrowing vaults and liquidity services can use the certificate to:

- approve a loan;
- set max loan amount;
- reduce collateral requirements;
- set interest rate;
- route borrower fees to a default fund;
- decide whether a borrower needs manual review;
- block borrowers with revoked or defaulted certificates.

Example policy:

```text
Approve if:
  certificate status = active
  score >= 750
  risk tier = low_default_risk
  ENS gate = passed
  certificate not expired
```

## Future Agent Layer

In the future, agents can use this credit identity and reputation layer to:

- request updated certificates;
- monitor borrower behavior;
- trigger repayment reminders;
- recommend credit limits;
- notify vaults when risk changes;
- coordinate between lenders, borrowers and insurance pools.

ERC-8004-style identity, reputation and validation can become the long-term protocol layer.

For the hackathon, we show the core primitive:

```text
Business wallet + confidential evidence + onchain behavior
  -> Credit Certificate
  -> Lending decision
  -> Default fund protection
```
