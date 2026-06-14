# LendSignal User Data Flow

## Purpose

This document explains what the business user fills in, how LendSignal processes that information, and how the Credit Certificate is updated and indexed through ENS.

## User Flow

```text
1. Business connects wallet
2. Business fills company profile
3. Business submits documents and KYC/KYB data
4. LendSignal enriches the profile with CRS credit bureau data
5. Chainlink Confidential AI processes sensitive evidence
6. Score Combiner creates final credit score
7. CreditCertificateRegistry is issued or updated
8. ENS text records point to the active certificate
9. Lending vault reads certificate and decides lending eligibility
```

## User Inputs

The business user provides:

- wallet address;
- ENS name;
- legal business name;
- country / market;
- business address;
- industry;
- monthly revenue band;
- requested loan amount;
- loan purpose;
- owner or authorized signer details;
- KYC/KYB status;
- business documents.

## Documents

For MVP, documents can be sample/mock uploads.

Required document checklist:

- business registration;
- tax identifier or tax record;
- bank statements;
- financial statements;
- invoices or accounts receivable data;
- accounts payable data;
- debt schedule;
- authorized signer document.

## Processing Layers

### CRS Credit Bureau Adapter

Consumes business and principal credit history data.

MVP mode:

- use `CRS_USE_MOCK=true`;
- return deterministic mock response.

Output:

- bureau score;
- business verification status;
- principal match status;
- payment risk;
- fraud risk;
- public records risk;
- recommended credit limit;
- raw report hash.

### Chainlink Confidential AI

Processes sensitive business evidence.

Output:

- business verified;
- document authenticity;
- fraud risk;
- cashflow strength;
- debt capacity;
- AI creditworthiness score;
- risk tier;
- attestation hash;
- evidence digest.

### Wallet Behavior Analyzer

Reads wallet-related behavior.

Output:

- wallet behavior score;
- wallet age;
- stablecoin flow signal;
- prior lending behavior;
- risk flags.

## Score Formula

```text
combinedScore =
  confidentialAiScore * 60%
  + crsBureauScore * 25%
  + walletBehaviorScore * 15%
```

Risk tiers:

```text
750-1000: low_default_risk
600-749: medium_default_risk
0-599: high_default_risk
```

## Certificate Update

CreditCertificateRegistry receives only processed public-safe information:

- business wallet;
- combined score;
- risk tier;
- certificate status;
- Chainlink attestation hash;
- CRS report hash;
- evidence digest;
- issued date;
- expiration date.

It does not receive:

- raw PDFs;
- raw CRS reports;
- bank statements;
- KYC/KYB documents;
- tax records;
- personal identity documents.

## ENS Indexing

ENS points to the active LendSignal certificate.

Recommended ENS text records:

```text
lendsignal.registry = <CreditCertificateRegistry address>
lendsignal.certificate = <certificate id>
lendsignal.attestation = <Chainlink attestation hash>
lendsignal.crs-report = <CRS report hash>
lendsignal.risk-tier = <risk tier>
lendsignal.agent = <LendSignal agent ENS name>
```

ENS is the discovery layer.

CreditCertificateRegistry is the source of truth.

## Lending Decision

The lending vault checks:

- ENS name resolves to borrower wallet;
- ENS text records point to LendSignal certificate;
- certificate is active;
- certificate is not expired;
- score is above threshold;
- risk tier is acceptable;
- vault has liquidity.

If all checks pass, the loan can be approved and paid out.

## Update Triggers

The certificate can be updated when:

- new documents are submitted;
- CRS report is refreshed;
- Chainlink AI review is re-run;
- wallet behavior changes;
- loan is repaid;
- loan defaults;
- KYC/KYB status changes.

## Demo Version

For the hackathon:

- business data is entered in the UI;
- documents are mocked;
- CRS response is mocked;
- Chainlink AI can be real or mocked depending on API key;
- CreditCertificateRegistry stores the final certificate;
- ENS records show certificate discovery;
- lending vault consumes the certificate.
