# LendSignal — Smart Contracts

Onchain credit layer for LendSignal. This package contains the contract that
**centralizes the offchain credit signals and defines each business's credit score**,
plus the skeleton of the lending contract that consumes it.

## Contracts

| # | Contract | Status | Purpose |
|---|----------|--------|---------|
| 1 | `CreditCertificateRegistry` | **Done (this phase)** | Centralizes the credit signals and defines the per-user score onchain. Single entry point for credit data. |
| 2 | `LendingVault` | Skeleton | Reads the registry to approve and pay out undercollateralized loans. Built next. |

## Phase 1 score sources

In this phase the score is built from **two** signals (wallet-behavior signal is
intentionally out of scope for now):

1. **Chainlink Confidential AI Attester** — the confidential credit reasoning ("CRI") signal.
2. **Offchain CRS credit-risk bureau** — normalized business credit signal.

```
combinedScore = confidentialAiScore * 70%  +  bureauScore * 30%
```

Weights live onchain (`aiWeightBps` / `bureauWeightBps`) and are owner-tunable, so the
score policy is auditable and adjustable without a redeploy.

Risk bands (derived from the combined score, 0–1000):

```
750–1000  ->  Low    (low_default_risk)
600–749   ->  Medium (medium_default_risk)
0–599     ->  High   (high_default_risk)
```

## How information enters

Raw documents, KYC/KYB and full bureau reports **never** go onchain. Only normalized
scores and content hashes are published.

```
LendSignal backend / Chainlink CRE workflow
  ├─ Chainlink Confidential AI Attester  -> confidentialAiScore + attestationHash
  └─ CRS credit-risk bureau (offchain)   -> bureauScore + bureauReportHash
        │
        ▼  (issuer EOA signs)
  CreditCertificateRegistry.issueCertificate(borrower, ScoreInputs)
        │
        ├─ blends the two scores into combinedScore (onchain weights)
        ├─ derives the RiskTier
        └─ stores an updateable CreditCertificate + emits SignalsRecorded / CertificateIssued
        │
        ▼
  LendingVault.isEligible(borrower)  ─►  loan approval / payout (contract #2)
```

`ScoreInputs` (in `src/libraries/CreditTypes.sol`) is the canonical payload that the
backend fills — it is the precise definition of "how the information enters".

## Access control

- `owner` — admin; rotates the issuer, tunes weights and the eligibility floor.
- `issuer` — the only address that can write certificates (the backend / CRE signer).

## Layout

```
src/
  CreditCertificateRegistry.sol     # contract #1 — centralizes signals + defines score
  LendingVault.sol                  # contract #2 — skeleton, reads the registry
  interfaces/
    ICreditCertificateRegistry.sol
    IERC20.sol
  libraries/
    CreditTypes.sol                 # enums, ScoreInputs, CreditCertificate, score math
script/
  Deploy.s.sol                      # deploys the registry
test/
  CreditCertificateRegistry.t.sol   # registry tests
  utils/Vm.sol                      # vendored cheatcode interface (no forge-std needed)
```

## Build, test, deploy

This package is dependency-free — `forge build` and `forge test` work without
`forge install`.

```bash
forge build
forge test -vvv

# deploy the registry
cp .env.example .env   # fill PRIVATE_KEY, RPC_URL, (optional) ISSUER
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
```
