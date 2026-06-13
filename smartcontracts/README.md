# LendSignal — Smart Contracts

Onchain credit layer for LendSignal. This package contains the contract that
**centralizes the offchain credit signals, defines each business's credit score, and
gates eligibility on an ENS identity**, plus the lending contract that consumes it.

## Contracts

| # | Contract | Status | Purpose |
|---|----------|--------|---------|
| 1 | `CreditCertificateRegistry` | **Done** | Centralizes the credit signals, defines the per-user score, and enforces the ENS gate onchain. Single entry point for credit data. |
| 2 | `LendingVault` | **Done** | Holds LP liquidity and issues undercollateralized loans gated by `registry.isEligible` (credit + ENS); built-in default-protection reserve. |

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

## ENS gate (contract #1)

ENS is a **real lending gate, not a cosmetic label**. The registry resolves the linked ENS
name onchain and only treats a certificate as eligible when the identity checks out.

```
issuer.linkEns(borrower, "acme.eth", namehash)   attach the ENS identity to the cert
        │
registry.isEnsVerified(borrower):
  1. ens.resolver(node)              must exist
  2. resolver.addr(node) == borrower forward resolution points back to the wallet
  3. (optional) resolver.text(node, "lendsignal.attestation") == attestationRecord(hash)
```

Configuration (owner):

- `setEnsRegistry(addr)` — point at the ENS registry (mainnet/Sepolia
  `0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e`). `address(0)` = not configured.
- `setEnsGateEnabled(bool)` — when on, `isEligible` also requires `isEnsVerified`.
- `setRequireAttestationRecord(bool)` — also check the `lendsignal.attestation` text record.

`attestationRecord(bytes32)` returns the exact string the text record must hold
(`0x`-prefixed lowercase hex of the attestation hash), so the frontend/backend can set it
deterministically. The namehash (`node`) is computed offchain and passed to `linkEns`.

## Lending flow (contract #2)

`LendingVault` turns an eligible certificate into a working-capital loan, with a built-in
default-protection reserve so the whole lending side stays in a single contract.

```
LP.deposit(amount)                       fund the vault's liquidity
Borrower.requestLoan(amount, days, ens)  requires registry.isEligible(borrower)
Owner.approveAndPayout(loanId)           re-checks the registry gate (credit + ENS), pays out
Borrower.repay(loanId)                   returns principal + fee; fee -> reserve
Owner.markDefault(loanId)                reserve reimburses the LP pool (capped at reserve)
```

Loan economics: the borrower receives the full `principal` and repays `principal + fee`
(`fee = principal * originationFeeBps`, default 3%). Repaid fees grow the `reserve`; on a
default the reserve refills `liquidity` so LPs are made whole up to the available reserve.
The vault has no ENS logic of its own — the credit + ENS gate is enforced entirely by
`registry.isEligible`, re-checked at payout time.

## End-to-end sequence

```mermaid
sequenceDiagram
  actor Biz as Business (wallet)
  participant BE as LendSignal Backend / CRE
  participant AI as Chainlink Confidential AI
  participant CRS as CRS Bureau (offchain)
  participant Reg as CreditCertificateRegistry
  participant ENS as ENS Registry + Resolver
  participant Vault as LendingVault

  Note over Biz,CRS: 1. Absorb + process info (OFF-CHAIN)
  Biz->>BE: business profile + documents + KYC/KYB
  BE->>AI: confidential inference (evidence)
  AI-->>BE: confidentialAiScore + attestationHash
  BE->>CRS: business credit query
  CRS-->>BE: bureauScore + bureauReportHash

  Note over BE,Reg: 2. Issue certificate (ON-CHAIN)
  BE->>Reg: issueCertificate(wallet, ScoreInputs)
  Reg->>Reg: combinedScore = AI*70% + bureau*30%; derive RiskTier
  Reg-->>Biz: CertificateIssued (score, tier, hashes)
  BE->>Reg: linkEns(wallet, "acme.eth", namehash)

  Note over Biz,ENS: 3. ENS identity (the gate)
  Biz->>ENS: addr(node)=wallet + text lendsignal.attestation

  Note over Biz,Vault: 4. Borrow
  Biz->>Vault: requestLoan(amount, days, ens)
  Vault->>Reg: isEligible(wallet)
  Reg->>ENS: resolver(node).addr(node) == wallet ?
  ENS-->>Reg: yes
  Reg-->>Vault: true (active + score + tier + ENS)
  Vault->>Reg: isEligible(wallet)  (re-check at payout)
  Vault-->>Biz: loan paid out (principal)
  Biz->>Vault: repay(principal + fee)   (fee -> protection reserve)
```

Two relationships make the design click:

- **wallet → certificate** — resolved by the registry (the wallet is the index/key).
- **ENS name → wallet → certificate** — resolved by ENS (human-readable identity + gate).

## Access control

- `owner` — admin; rotates the issuer, tunes weights, the eligibility floor and the ENS gate.
- `issuer` — the only address that can write certificates and link ENS names (backend / CRE signer).

## Layout

```
src/
  CreditCertificateRegistry.sol         # contract #1 — signals + score + ENS gate
  LendingVault.sol                      # contract #2 — score-gated loans + default reserve
  interfaces/
    ICreditCertificateRegistry.sol
    IENS.sol                            # minimal ENS registry + resolver interfaces
    IERC20.sol
  libraries/
    CreditTypes.sol                     # enums, ScoreInputs, CreditCertificate, score math
  mocks/
    MockERC20.sol                       # demo loan asset (USDC-like)
    MockENSRegistry.sol                 # demo ENS registry
    MockPublicResolver.sol              # demo ENS resolver (addr + text records)
script/
  Deploy.s.sol                          # deploys registry + vault (+ mock asset / ENS wiring)
test/
  CreditCertificateRegistry.t.sol       # registry score/lifecycle tests
  CreditCertificateRegistryEns.t.sol    # registry ENS-gate tests
  LendingVault.t.sol                    # vault tests
  utils/Vm.sol                          # vendored cheatcode interface (no forge-std needed)
```

## Build, test, deploy

This package is dependency-free — `forge build` and `forge test` work without
`forge install`. 24 tests across the three suites.

```bash
forge build
forge test -vvv

# deploy registry + vault
cp .env.example .env   # fill PRIVATE_KEY, RPC_URL, (optional) ISSUER, ASSET, ENS_REGISTRY
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
```
