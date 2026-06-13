# Business Proposal

## Product Name

Selected name: **LendSignal**

Previous naming options:

- AttestaCredit
- RiskPassport
- SignalPass
- CreditLayer
- ProofWorth
- TradeCred

## Vision

LendSignal is a confidential creditworthiness infrastructure layer for B2B onchain finance.

It enables lending protocols and working-capital vaults to make better risk decisions by combining onchain behavior, private business financials, curator attestations and verifiable AI scoring without exposing raw borrower documents.

## Problem

DeFi and onchain finance are limited by incomplete identity and risk context.

Protocols can see:

- wallet balances;
- token transfers;
- collateral;
- DeFi positions;
- liquidations;
- protocol interactions.

But they usually cannot verify:

- whether a wallet belongs to a real person or business;
- business revenue;
- cashflow coverage;
- financial statement health;
- invoices;
- debt obligations;
- accounts receivable quality;
- repayment capacity;
- KYB/KYC status;
- offchain payment history;
- supplier relationships;
- signing authority;
- business reputation.

Because of this, many protocols rely on excessive collateral or cannot serve real-world businesses that need working capital.

## Opportunity

The next phase of onchain finance needs portable, privacy-conscious and verifiable creditworthiness.

This is especially valuable for:

- undercollateralized lending;
- business credit lines;
- invoice financing;
- liquidity provider approval;
- stablecoin settlement networks;
- agent marketplaces;
- merchant financing;
- B2B payments.
- working-capital lending vaults.

## Solution

LendSignal creates a **Credit Passport** for business wallets.

The passport combines:

- onchain financial history;
- private business financial documents;
- AI-derived financial metrics;
- offchain verified business data;
- curator-signed attestations;
- confidential compute proof metadata;
- risk scoring;
- privacy-preserving proofs;
- portable reputation.

Protocols consume the passport to make decisions such as:

- approve or reject a borrower;
- adjust collateral requirements;
- set credit limits;
- gate borrowing-lending vault access;
- rank liquidity providers;
- reduce bond requirements;
- allow access to premium pools;
- trigger risk workflows.

## Key Differentiator

LendSignal does not try to become a credit bureau or store private borrower documents.

Instead, it creates a **confidential attestation network**.

Trusted data providers, KYC/KYB companies, credit data vendors, open banking providers, accounting systems, invoice platforms, DECO-style verifiers and onchain analytics services can act as paid curators.

Each curator contributes signed attestations. A Chainlink CRE + Confidential AI Attester-style workflow converts sensitive borrower data into a verifiable score and proof metadata.

LendSignal aggregates those attestations into a protocol-consumable passport.

## Example

A small business connects its wallet.

LendSignal analyzes:

- wallet age;
- stablecoin cashflow;
- Aave/Morpho lending history;
- repayment behavior;
- liquidation history;
- risk exposure.

The business uploads or selects mock confidential documents:

- financial statements;
- bank statements;
- tax return metadata;
- accounts receivable aging;
- accounts payable aging;
- debt schedule;
- business legal documents.

The business also connects curators:

- KYB provider;
- bank revenue provider;
- invoice/payment provider;
- business credit data provider.
- AML/sanctions provider.

LendSignal generates:

```text
Credit Passport
  Creditworthiness score: 820/1000
  Default risk tier: Low
  Business verified: true
  Revenue band: $50k-$100k monthly
  Onchain risk: low
  Liquidations: none
  Repayment history: clean
  Credit tier: A-
  Suggested credit line: $25,000
```

A lending vault reads this passport and offers better terms.

```text
Without LendSignal
  Max loan: $5,000
  Collateral required: 150%
  Rate: 14%

With LendSignal
  Max loan: $25,000
  Collateral required: 90%
  Rate: 9%
```

## Business Model

### 1. Attestation Fees

Protocols pay to request fresh or specialized attestations.

Revenue is shared with curators.

### 2. Passport Subscription

Businesses pay to maintain a live passport.

### 3. Protocol API Fees

Protocols pay for API access, webhooks and risk feeds.

### 4. Curator Marketplace Fees

Curators earn when their signals are consumed.

LendSignal takes a network fee.

### 5. Enterprise Risk Packages

Custom scoring, compliance workflows and private deployments for lenders, payment companies and institutional protocols.

### 6. Default Fund Fees

Borrowers or lenders pay a reserve fee for optional coverage from an insurance-style default fund.

## Target Customers

### First Customers

- Onchain lending protocols.
- Invoice financing protocols.
- Working-capital lending vaults.
- OTC/liquidity networks.
- Stablecoin payment platforms.
- Web3 business banking products.

### Later Customers

- Fintechs.
- Neobanks.
- Marketplaces.
- B2B payment networks.
- Institutional DeFi platforms.

## MVP Goal

Demonstrate that a lending vault can improve its credit decision using a business-wallet passport powered by onchain history, confidential document analysis and curator attestations.

## MVP Success Criteria

- A wallet can generate a Credit Passport.
- The passport includes onchain, financial-document and curator signals.
- A confidential AI attestation produces a Creditworthiness Score.
- A curator signs at least one offchain attestation.
- A demo lending vault consumes the passport.
- The vault changes loan terms based on the score.
- ENS/passport gating is shown.
- Optional default fund coverage is shown.
- The user’s private raw data is not exposed.
