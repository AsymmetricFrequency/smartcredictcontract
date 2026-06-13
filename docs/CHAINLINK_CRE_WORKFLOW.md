# Chainlink CRE Confidential Scoring Workflow

## Goal

Use a Chainlink CRE-style workflow with Confidential Compute and a Confidential AI Attester to generate a verifiable Creditworthiness Score for B2B working-capital lending.

The key promise is simple:

```text
Borrower private data goes in.
Only an attested score, risk tier, proof metadata and summary come out.
```

## Borrower Inputs

The borrower submits documents through the app:

- business financial statements for the last 2-3 years and year-to-date;
- tax returns;
- bank statements for the last 6-12 months;
- accounts receivable aging report;
- accounts payable aging report;
- inventory listing when relevant;
- debt schedule;
- business legal documents.

For the MVP, these can be represented as sample PDFs, JSON files or preloaded borrower profiles.

## Workflow Steps

### 1. Application And Upload

The borrower connects a business wallet and submits documents through the LendSignal frontend.

Documents are encrypted and passed into a confidential scoring workflow. In the MVP, this is simulated.

### 2. Confidential Ingestion

Inside the confidential workflow, the system extracts structured values:

- revenue;
- expenses;
- assets;
- liabilities;
- receivables;
- payables;
- cash balance;
- debt payments;
- inventory;
- growth trend.

It also checks authenticity and fraud signals:

- document consistency;
- unusual receivables patterns;
- mismatch between revenue, invoices and bank flows;
- missing periods;
- tampering indicators.

### 3. Financial Metric Calculation

The scoring engine calculates borrower risk metrics:

- Current Ratio;
- Quick Ratio;
- DSCR;
- EBITDA;
- cash burn;
- leverage;
- receivables concentration;
- cashflow volatility;
- revenue growth.

### 4. External Cross-Verification

The workflow cross-checks facts with privacy-preserving sources:

- KYB provider;
- AML/sanctions provider;
- business credit provider;
- open banking or bank-balance proof;
- invoice/payment processor;
- DECO-style web/API fact verification.

The goal is to verify claims like:

- bank balance is above a threshold;
- business registration is active;
- no major default is reported;
- invoice/payment history is consistent;
- revenue band matches the submitted documents.

### 5. AI Attester Scoring

The Confidential AI Attester analyzes:

- document-derived metrics and trends;
- cross-verified external data;
- onchain repayment and liquidation history;
- qualitative signals like sector risk and growth plan realism.

It produces:

- Creditworthiness Score from `0-1000`;
- default-risk tier;
- short explanation;
- evidence hash;
- compute/proof metadata;
- signed attestation.

Example output:

```json
{
  "score": 820,
  "riskTier": "low_default_risk",
  "summary": "Financials validated, stable cashflow, clean repayment history, no major defaults found.",
  "evidenceHash": "0x...",
  "computeProof": "0x..."
}
```

### 6. Onchain Or Protocol Output

LendSignal publishes or exposes only:

- attested score;
- risk tier;
- summary;
- proof hash;
- passport hash;
- expiration;
- revocation status.

Raw business documents are not published.

## Lending Vault Usage

A lending vault can gate loan deployment by checking:

- valid Credit Passport;
- minimum score;
- acceptable default-risk tier;
- active ENS pointer or registry entry;
- no revocation;
- optional default fund coverage.

Example policy:

```text
Score >= 800 and risk tier = Low:
  max loan $25,000
  collateral 80-100%
  rate 9%

Score 600-799 and risk tier = Medium:
  max loan $10,000
  collateral 120%
  rate 12%

Score < 600 or invalid passport:
  reject or require 150% collateral
```

## MVP Implementation

The hackathon implementation should not depend on real early-access confidential compute.

Build a faithful simulator:

- mock document profiles;
- deterministic metric extraction;
- mock AI attester signature;
- mock external fact verification;
- onchain or local registry for passport hash;
- lending vault UI that changes terms based on score.

This keeps the demo real enough to communicate the product while staying buildable during the hackathon.
