# LendSignal Architecture

## Architecture Goal

LendSignal turns a business wallet into an updateable onchain Credit Certificate.

The certificate is generated from:

- business onboarding data;
- mock KYC/KYB and documents;
- Chainlink Confidential AI Attester output;
- CRS credit bureau signal;
- wallet behavior;
- ENS identity records.

The certificate is then consumed by a lending vault, while Uniswap is used to execute liquidity and fee conversion into the vault/default-fund asset.

## System Diagram

```mermaid
flowchart LR
  B["Business borrower"] --> FE["LendSignal web app"]
  FE --> W["Wallet connection"]
  FE --> ONB["Business onboarding"]
  FE --> DOCS["Documents + KYC/KYB mock"]
  FE --> ENSUI["ENS identity input"]

  ONB --> API["LendSignal backend"]
  DOCS --> API
  W --> API
  ENSUI --> API

  API --> CAI["Chainlink Confidential AI Attester"]
  API --> CRS["CRS Credit Bureau Adapter"]
  API --> WB["Wallet Behavior Analyzer"]
  API --> SCORER["Score Combiner"]

  CAI --> SCORER
  CRS --> SCORER
  WB --> SCORER

  SCORER --> CERT["CreditCertificateRegistry"]
  ENSUI --> ENS["ENS Resolver + Text Records"]

  CERT --> VAULT["LendingVault"]
  ENS --> VAULT
  VAULT --> BORROWER_FUNDS["Loan payout"]
  VAULT --> FEE["Borrower fee"]
  FEE --> DF["DefaultFund"]

  LP["Liquidity provider"] --> UNI["Uniswap API Swap"]
  UNI --> VAULT
  UNI --> DF

  DF --> REIMB["Default reimbursement"]
```

## Component Responsibilities

| Component | Responsibility | Hackathon Implementation |
|---|---|---|
| Web app | User-facing onboarding, score, certificate, vault and default fund flows | Next.js or equivalent frontend |
| LendSignal backend | Orchestrates offchain APIs, mocks, score calculation and contract writes | API routes/server actions |
| Chainlink Confidential AI adapter | Processes sensitive borrower evidence and returns structured credit output | Real API if key exists, mock fallback otherwise |
| CRS Credit Bureau Adapter | Pulls business/principal credit-history data and normalizes it | Mock CRS response now, real CRS later |
| Wallet Behavior Analyzer | Scores wallet age, stablecoin activity, repayment activity and risk flags | Deterministic mock or simple onchain scan |
| Score Combiner | Produces final `combinedScore` and risk tier | 60% AI, 25% CRS, 15% wallet behavior |
| CreditCertificateRegistry | Stores updateable onchain certificate | Solidity contract |
| ENS Resolver/Gate | Resolves business name and validates text records | ENS read integration |
| LendingVault | Approves and pays out loans based on certificate policy | Solidity contract |
| Uniswap API integration | Converts LP/borrower tokens into vault/default-fund asset | Quote + swap + tx hash |
| DefaultFund | Holds protection liquidity and reimburses defaults | Solidity contract |

## End-To-End Data Flow

```mermaid
sequenceDiagram
  participant Biz as Business
  participant App as LendSignal App
  participant CRS as CRS Adapter
  participant AI as Chainlink Confidential AI
  participant Score as Score Combiner
  participant Cert as CreditCertificateRegistry
  participant ENS as ENS
  participant Vault as LendingVault
  participant Uni as Uniswap API
  participant Fund as DefaultFund

  Biz->>App: Connect wallet + submit business profile
  Biz->>App: Submit mock docs + KYC/KYB status
  App->>AI: Submit inference request with resources
  AI-->>App: Return credit AI output + digests
  App->>CRS: Evaluate business credit history
  CRS-->>App: Return normalized bureau signal
  App->>Score: Combine AI + CRS + wallet behavior
  Score-->>App: combinedScore + riskTier + hashes
  App->>Cert: issueCertificate(...)
  Cert-->>App: CertificateIssued tx
  App->>ENS: Resolve name + read text records
  App->>Vault: requestLoan(amount, ensName)
  Vault->>Cert: Read certificate
  Vault->>ENS: Verify ENS gate
  Vault-->>Biz: Automatic loan payout
  Biz->>Uni: Swap fee token to vault asset
  Uni-->>Fund: Deposit converted fee/liquidity
  Fund-->>Vault: Reimburse if default occurs
```

## Scoring Architecture

```mermaid
flowchart TD
  AI["Confidential AI Attester score"] --> COMB["Score Combiner"]
  CRS["CRS bureau score"] --> COMB
  WB["Wallet behavior score"] --> COMB

  COMB --> SCORE["combinedScore = AI 60% + CRS 25% + Wallet 15%"]
  SCORE --> TIER{"Risk tier"}
  TIER -->|750-1000| LOW["low_default_risk"]
  TIER -->|600-749| MED["medium_default_risk"]
  TIER -->|0-599| HIGH["high_default_risk"]
  LOW --> CERT["Credit Certificate"]
  MED --> CERT
  HIGH --> CERT
```

## Offchain Services

### Chainlink Confidential AI Adapter

Inputs:

- business profile;
- document resources;
- KYC/KYB mock status;
- requested loan purpose;
- prompt.

Outputs:

- `business_verified`;
- `document_authenticity`;
- `fraud_risk`;
- `cashflow_strength`;
- `debt_capacity`;
- `creditworthiness_score`;
- `risk_tier`;
- `reasoning_summary`;
- resource digests.

### CRS Credit Bureau Adapter

Inputs:

- legal business name;
- address/country/state;
- industry;
- business wallet;
- owner/principal metadata if available.

Outputs:

- `businessVerified`;
- `principalMatched`;
- `bureauScore`;
- `paymentRisk`;
- `fraudRisk`;
- `publicRecordsRisk`;
- `recommendedCreditLimitUsd`;
- `delinquencyRisk12mo`;
- positive/adverse signal summary;
- `rawReportHash`.

### Wallet Behavior Analyzer

Inputs:

- wallet address;
- token activity;
- stablecoin flow;
- lending/borrowing interactions;
- liquidation/default history if available.

Outputs:

- `walletBehaviorScore`;
- risk flags;
- summary.

## Onchain Architecture

```mermaid
flowchart LR
  CERT["CreditCertificateRegistry"] --> VAULT["LendingVault"]
  ENS["ENS Resolver / Text Records"] --> VAULT
  VAULT --> LOAN["Loan records"]
  VAULT --> ASSET["Loan asset ERC20"]
  VAULT --> FUND["DefaultFund"]
  UNI["Uniswap swap tx"] --> FUND
  UNI --> VAULT
  FUND --> CLAIM["Default reimbursement"]
```

Onchain contracts:

- `CreditCertificateRegistry`;
- `LendingVault`;
- `DefaultFund`;
- optional mock ERC20 asset for local/testnet demo.

External onchain dependencies:

- ENS resolver reads;
- Uniswap swap transaction;
- ERC20 loan/default-fund asset.

## Certificate Lifecycle

```mermaid
stateDiagram-v2
  [*] --> Pending
  Pending --> Active: issueCertificate
  Active --> Updated: updateCertificate
  Updated --> Active: new certificate version active
  Active --> Expired: expiresAt < block.timestamp
  Active --> Revoked: revokeCertificate
  Active --> Defaulted: markDefault
  Expired --> Active: refresh certificate
  Revoked --> [*]
  Defaulted --> [*]
```

## Lending Decision Flow

```mermaid
flowchart TD
  REQ["Borrower requests loan"] --> READ["Read CreditCertificateRegistry"]
  READ --> ACTIVE{"Certificate active?"}
  ACTIVE -->|No| REJECT["Reject"]
  ACTIVE -->|Yes| EXP{"Not expired?"}
  EXP -->|No| REJECT
  EXP -->|Yes| SCORE{"Score >= 750?"}
  SCORE -->|No| REJECT
  SCORE -->|Yes| ENSG{"ENS gate passed?"}
  ENSG -->|No| REJECT
  ENSG -->|Yes| LIQ{"Vault has liquidity?"}
  LIQ -->|No| REJECT
  LIQ -->|Yes| FEE["Calculate borrower fee"]
  FEE --> PAY["Transfer loan asset to borrower"]
  PAY --> ROUTE["Route fee to DefaultFund"]
  ROUTE --> LOAN["Create loan record"]
```

## Uniswap Integration Architecture

```mermaid
sequenceDiagram
  participant User as LP / Borrower
  participant App as LendSignal App
  participant Uni as Uniswap API
  participant Wallet as User Wallet
  participant Fund as DefaultFund / Vault

  User->>App: Select token + amount + target
  App->>Uni: Check approval
  Uni-->>App: Approval requirement
  App->>Uni: Request quote
  Uni-->>App: Quote + route
  App->>Uni: Request swap transaction
  Uni-->>App: Unsigned tx payload
  App->>Wallet: Ask user to sign/send tx
  Wallet-->>App: Swap tx hash
  App->>Fund: Deposit converted asset
  Fund-->>App: Deposit tx hash
```

Use cases:

- LP deposits WETH or another token, then Uniswap converts to USDC/default-fund asset.
- Borrower pays fee in any supported token, then Uniswap converts fee to default-fund asset.

## ENS Architecture

```mermaid
flowchart TD
  NAME["business.eth"] --> RESOLVE["Resolve address"]
  RESOLVE --> MATCH{"Resolved address == borrower wallet?"}
  NAME --> TEXT["Read text records"]
  TEXT --> CERTREC["lendsignal.certificate"]
  TEXT --> ATTREC["lendsignal.attestation"]
  TEXT --> AGENT["lendsignal.agent"]
  MATCH --> GATE{"ENS gate"}
  CERTREC --> GATE
  ATTREC --> GATE
  GATE -->|Pass| VAULT["Loan approval can continue"]
  GATE -->|Fail| REJECT["Reject / manual review"]
```

Required text records:

```text
lendsignal.certificate = <certificateId or registry pointer>
lendsignal.attestation = <attestationHash>
lendsignal.risk-tier = <risk tier>
lendsignal.agent = <agent ENS name>
```

## Privacy Boundary

```mermaid
flowchart LR
  PRIVATE["Private data: docs, KYC/KYB, CRS raw report"] --> OFFCHAIN["Offchain processing"]
  OFFCHAIN --> HASHES["Hashes + digests"]
  OFFCHAIN --> SUMMARY["Scores + risk bands"]
  HASHES --> ONCHAIN["Onchain certificate"]
  SUMMARY --> ONCHAIN
  PRIVATE -. never published .-> BLOCK["Not stored onchain"]
```

Do not put onchain:

- raw documents;
- full CRS reports;
- full KYC/KYB records;
- bank statements;
- tax records;
- private invoices;
- personal identity documents.

Publish onchain:

- business wallet;
- score;
- risk tier;
- certificate status;
- attestation hash;
- evidence digest;
- expiration.

## Deployment View

```mermaid
flowchart TB
  subgraph Browser
    UI["LendSignal frontend"]
    Wallet["Wallet provider"]
  end

  subgraph Backend
    API["API routes"]
    AIAdapter["Chainlink AI adapter"]
    CRSAdapter["CRS mock/real adapter"]
    ScoreSvc["Score service"]
    ENSAdapter["ENS resolver service"]
    UniAdapter["Uniswap API adapter"]
  end

  subgraph Chain
    Cert["CreditCertificateRegistry"]
    Vault["LendingVault"]
    Fund["DefaultFund"]
    ERC20["ERC20 asset"]
  end

  UI --> API
  UI --> Wallet
  API --> AIAdapter
  API --> CRSAdapter
  API --> ScoreSvc
  API --> ENSAdapter
  API --> UniAdapter
  Wallet --> Cert
  Wallet --> Vault
  Wallet --> Fund
  Wallet --> ERC20
```
