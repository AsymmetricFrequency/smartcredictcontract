# LendSignal — Smart Contracts

Onchain credit layer for LendSignal. This package contains the contract that
**centralizes the offchain credit signals and defines each business's credit score**,
plus the skeleton of the lending contract that consumes it.

## Contracts

| # | Contract | Status | Purpose |
|---|----------|--------|---------|
| 1 | `CreditCertificateRegistry` | **Done** | Centralizes the credit signals and defines the per-user score onchain. Single entry point for credit data. |
| 2 | `LendingVault` | **Done** | Holds LP liquidity and issues undercollateralized loans gated by the registry score; built-in default-protection reserve. |

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

## Lending flow (contract #2)

`LendingVault` turns an eligible certificate into a working-capital loan, with a built-in
default-protection reserve so the whole lending side stays in a single contract.

```
LP.deposit(amount)                       fund the vault's liquidity
Borrower.requestLoan(amount, days, ens)  requires registry.isEligible(borrower)
Owner.approveAndPayout(loanId)           re-checks eligibility (+ optional ENS), pays out
Borrower.repay(loanId)                   returns principal + fee; fee -> reserve
Owner.markDefault(loanId)                reserve reimburses the LP pool (capped at reserve)
```

Loan economics: the borrower receives the full `principal` and repays `principal + fee`
(`fee = principal * originationFeeBps`, default 3%). Repaid fees grow the `reserve`; on a
default the reserve refills `liquidity` so LPs are made whole up to the available reserve.
An optional `IENSVerifier` (off by default) enforces an ENS gate at payout time.

## Access control

- `owner` — admin; rotates the issuer, tunes weights and the eligibility floor.
- `issuer` — the only address that can write certificates (the backend / CRE signer).

## Layout

```
src/
  CreditCertificateRegistry.sol     # contract #1 — centralizes signals + defines score
  LendingVault.sol                  # contract #2 — score-gated loans + default reserve
  interfaces/
    ICreditCertificateRegistry.sol
    IENSVerifier.sol
    IERC20.sol
  libraries/
    CreditTypes.sol                 # enums, ScoreInputs, CreditCertificate, score math
  mocks/
    MockERC20.sol                   # demo loan asset (USDC-like)
    MockENSVerifier.sol             # demo ENS gate
script/
  Deploy.s.sol                      # deploys registry + vault (+ mock asset if needed)
test/
  CreditCertificateRegistry.t.sol   # registry tests
  LendingVault.t.sol                # vault tests
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
