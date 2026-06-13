# Demo Script

## Goal

Show how a business creates an onchain Credit Certificate from confidential evidence and uses it to receive an automatic working-capital loan payout.

## Scene 1 — Business Onboarding

User connects wallet and submits business information.

UI shows:

- borrower name;
- country or market;
- industry;
- requested loan amount;
- wallet address;
- KYC/KYB status;
- document checklist;
- ENS gate status;

Narration:

```text
The business wallet becomes the onchain identity used by lenders, liquidity pools and future agents.
```

## Scene 2 — Generate Credit Worthiness Score

LendSignal sends the business evidence through a Confidential AI Attester-style workflow and combines the result with bureau and wallet behavior signals.

UI shows:

- Confidential AI Attester score;
- 3rd party credit bureau score;
- wallet behavior score;
- combined score;
- risk tier;
- attestation hash.
- evidence digest.

Narration:

```text
The raw borrower data stays private. The public layer receives only a score, risk tier, attestation hash and evidence digest.
```

## Scene 3 — Issue Credit Certificate

LendSignal issues an updateable Credit Certificate for the connected wallet.

UI shows:

- certificate id;
- certificate status;
- certificate registry status;
- ENS record status;
- approval threshold;
- issued date;
- expiration.

Example result:

```text
Confidential AI score: 840
Credit bureau score: 780
Wallet behavior score: 760
Combined Credit Worthiness Score: 816
Default risk: Low
Certificate: Active
ENS gate: Passed
```

## Scene 4 — Lending Vault Approves And Pays Out

Demo lending vault shows before/after:

Without LendSignal:

- max loan: $5,000;
- collateral: 150%;
- rate: 14%.

With LendSignal:

- max loan: $25,000;
- collateral: score-based / reduced collateral;
- rate: 9%.

Approval checks:

- Credit Certificate active;
- Certificate not expired;
- Credit Worthiness Score >= 750;
- ENS gate passed;
- vault has liquidity.

Narration:

```text
The vault can now approve and pay out based on a verifiable risk signal instead of demanding excessive collateral.
```

## Scene 5 — Insurance Default Fund

Show:

- default fund liquidity;
- coverage ratio;
- covered loan amount;
- reserve fee;
- claim status.

Narration:

```text
For lenders, the default fund adds another safety layer around undercollateralized lending.
```

## Scene 6 — Verification

Show:

- AI attester signature;
- certificate registry entry;
- evidence hash;
- compute proof metadata;
- expiration;
- privacy note;
- raw sensitive data not exposed.

## Closing Line

LendSignal turns a business wallet into an updateable onchain credit certificate, enabling working-capital loans through confidential verification, ENS-gated approval and decentralized default protection.
