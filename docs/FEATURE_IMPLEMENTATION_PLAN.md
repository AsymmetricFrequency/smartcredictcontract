# LendSignal Feature Implementation Plan

## Goal

Build LendSignal as an onchain credit certification and lending demo for B2B working-capital loans.

The product loop:

```text
Business onboarding
  -> confidential credit verification
  -> offchain credit bureau enrichment
  -> updateable onchain Credit Certificate
  -> ENS-discoverable credit identity
  -> lending vault approval and payout
  -> Uniswap-powered liquidity / fee conversion
  -> default fund protection
```

## Sponsor Strategy

### Chainlink

Use Chainlink as the trust layer for confidential credit reasoning.

Target prizes:

- Best usage of Chainlink Confidential AI Attester.
- Best workflow with CRE.
- Chainlink core prize if the workflow contributes to a blockchain state change.

Proof to show:

- at least one Confidential AI inference request;
- CRE workflow simulation or deployment;
- certificate issued onchain from the attested result.

### ENS

Use ENS as the identity and discovery layer for businesses and agents.

Target prizes:

- Integrate ENS.
- Most Creative Use of ENS.
- Best ENS Integration for AI Agents if we expose LendSignal as an agent with ENS records.

Proof to show:

- resolve ENS dynamically;
- read text records for certificate/attestation metadata;
- use ENS as a real lending gate, not a cosmetic label.

### Uniswap

Use Uniswap as the liquidity and value execution layer.

Target prize:

- Best Uniswap API Integration.

Proof to show:

- use Uniswap Developer Platform API key;
- request a quote;
- execute an onchain swap;
- show transaction ID;
- route swapped assets to the vault or default fund.

## Feature 1: Business Onboarding

### What We Implement

A borrower flow where a business:

- connects wallet;
- enters business profile;
- selects or uploads mock documents;
- completes mock KYC/KYB;
- links an ENS name;
- requests a working-capital loan.

### Frontend

Route:

```text
/onboarding
```

UI:

- wallet connect;
- business information form;
- document checklist;
- KYC/KYB status;
- ENS name input;
- requested loan amount;
- submit for scoring button.

### Data

Use preloaded borrower profiles:

- strong borrower: score passes;
- medium borrower: manual review;
- weak borrower: rejected.

The connected wallet is the identity key used by:

- CreditCertificateRegistry;
- LendingVault;
- DefaultFund;
- ENS records.

## Feature 2: Chainlink Confidential Credit Verification

### What We Implement

Use the Chainlink Confidential AI Attester demo API to process sensitive borrower evidence and return structured credit output.

If the API key is unavailable, use deterministic mock output with the same response shape.

### API

```text
BASE_URL=https://confidential-ai-dev-preview.cldev.cloud
GET /v1/models
POST /v1/inference
GET /v1/inference/:id
```

Environment:

```text
CHAINLINK_CONFIDENTIAL_AI_BASE_URL=https://confidential-ai-dev-preview.cldev.cloud
CHAINLINK_CONFIDENTIAL_AI_API_KEY=
CHAINLINK_CONFIDENTIAL_AI_MODEL=gemma4
```

### Flow

1. Build prompt from borrower profile.
2. Attach uploaded/mock documents as resources.
3. Submit `POST /v1/inference`.
4. Poll `GET /v1/inference/:id`.
5. Parse JSON output.
6. Hash output and resource digests.
7. Issue/update certificate onchain.

### Prompt

```text
You are evaluating a business borrower for an onchain working-capital loan.

Return only JSON:
{
  "business_verified": boolean,
  "document_authenticity": "low" | "medium" | "high",
  "fraud_risk": "low" | "medium" | "high",
  "cashflow_strength": "low" | "medium" | "high",
  "debt_capacity": "low" | "medium" | "high",
  "creditworthiness_score": number,
  "risk_tier": "low_default_risk" | "medium_default_risk" | "high_default_risk",
  "reasoning_summary": string,
  "missing_information": string[]
}

Do not expose raw private document content.
```

### Score Combination

```text
combinedScore =
  confidentialAiScore * 60%
  + bureauScore * 25%
  + walletBehaviorScore * 15%
```

### CRE Workflow

Build or simulate a CRE workflow:

```text
Borrower wallet + evidence digest
  -> Confidential AI request / mock adapter
  -> score calculation
  -> CreditCertificateRegistry.issueCertificate(...)
```

The Chainlink-derived result must trigger a blockchain state change.

## Feature 3: CRS Credit Bureau Adapter

### What We Implement

An offchain service that consumes business and principal credit history data from CRS Credit API.

For the hackathon, because we do not have production API keys yet, we implement a mock adapter with the same internal response shape that the real CRS integration will use later.

This service centralizes:

- borrower business profile;
- KYC/KYB status;
- submitted business documents;
- CRS/business credit data;
- principal/owner credit indicators when available;
- wallet behavior;
- Confidential AI Attester output.

The output becomes the normalized bureau/risk signal used by LendSignal to generate the final Credit Certificate.

### Why CRS Fits

CRS exposes credit-data products for:

- consumer credit;
- business credit;
- alternative credit;
- identity and fraud;
- public records.

For LendSignal, the most relevant business-credit products are:

- business risk dashboards;
- business Intelliscore / scores;
- business facts;
- business fraud shields;
- business compliance insight;
- business contacts and principals;
- business trades;
- bankruptcies, liens, judgments, UCC filings and collections.

### Service Name

```text
CreditBureauAdapter
```

### Route

```text
POST /api/credit-bureau/evaluate
```

### Request

```typescript
type CreditBureauRequest = {
  businessProfileId: string;
  businessWallet: string;
  legalName: string;
  dbaName?: string;
  country: string;
  state?: string;
  city?: string;
  address?: string;
  taxIdLast4?: string;
  industry?: string;
  ownerOrPrincipal?: {
    name: string;
    role: string;
    ownershipPct?: number;
  };
};
```

### Normalized Response

```typescript
type CreditBureauSignal = {
  provider: 'crs_mock' | 'crs';
  reportId: string;
  businessVerified: boolean;
  principalMatched: boolean;
  bureauScore: number;
  paymentRisk: 'low' | 'medium' | 'high';
  fraudRisk: 'low' | 'medium' | 'high';
  publicRecordsRisk: 'low' | 'medium' | 'high';
  recommendedCreditLimitUsd: number;
  delinquencyRisk12mo: number;
  adverseSignals: string[];
  positiveSignals: string[];
  rawReportHash: string;
  pulledAt: string;
};
```

### Mock Response

```json
{
  "provider": "crs_mock",
  "reportId": "crs_mock_001",
  "businessVerified": true,
  "principalMatched": true,
  "bureauScore": 782,
  "paymentRisk": "low",
  "fraudRisk": "low",
  "publicRecordsRisk": "low",
  "recommendedCreditLimitUsd": 30000,
  "delinquencyRisk12mo": 0.08,
  "adverseSignals": [],
  "positiveSignals": [
    "business identity matched",
    "no bankruptcy records found",
    "low days-beyond-terms indicator",
    "positive trade payment history"
  ],
  "rawReportHash": "0x...",
  "pulledAt": "2026-06-13T00:00:00Z"
}
```

### Real CRS Integration Later

When API keys are available:

1. Authenticate against CRS.
2. Search/identify the business.
3. Pull the relevant business credit products.
4. Normalize the response into `CreditBureauSignal`.
5. Hash the raw report.
6. Store only normalized signals and report hash in LendSignal.

### Environment

```text
CRS_API_BASE_URL=
CRS_API_CLIENT_ID=
CRS_API_CLIENT_SECRET=
CRS_API_USERNAME=
CRS_API_PASSWORD=
CRS_USE_MOCK=true
```

### How It Affects The Score

The bureau signal becomes the `bureauScore` in the LendSignal score formula.

```text
combinedScore =
  confidentialAiScore * 60%
  + bureauScore * 25%
  + walletBehaviorScore * 15%
```

For the hackathon, use deterministic scoring:

```text
Strong borrower:
  bureauScore = 782
  paymentRisk = low
  fraudRisk = low

Medium borrower:
  bureauScore = 668
  paymentRisk = medium
  fraudRisk = low

Weak borrower:
  bureauScore = 540
  paymentRisk = high
  fraudRisk = medium
```

### Privacy Rule

Do not put raw CRS reports onchain.

Only expose:

- normalized bureau score;
- risk bands;
- report hash;
- pulled timestamp;
- positive/adverse signal summary.

## Feature 4: Credit Certificate Registry

### What We Implement

A contract that stores an updateable credit certificate for each business wallet.

### Contract Shape

```solidity
contract CreditCertificateRegistry {
    enum RiskTier {
        High,
        Medium,
        Low
    }

    struct CreditCertificate {
        uint256 score;
        RiskTier riskTier;
        bytes32 attestationHash;
        bytes32 evidenceDigest;
        uint256 issuedAt;
        uint256 expiresAt;
        bool active;
    }

    mapping(address => CreditCertificate) public certificates;

    function issueCertificate(
        address borrower,
        uint256 score,
        RiskTier riskTier,
        bytes32 attestationHash,
        bytes32 evidenceDigest,
        uint256 expiresAt
    ) external;

    function updateCertificate(
        address borrower,
        uint256 score,
        RiskTier riskTier,
        bytes32 attestationHash,
        bytes32 evidenceDigest,
        uint256 expiresAt
    ) external;

    function revokeCertificate(address borrower) external;
    function isEligible(address borrower) external view returns (bool);
}
```

### Demo Proof

Show transaction IDs for:

- certificate issued;
- certificate updated or revoked if time allows.

## Feature 5: ENS Credit Identity

### What We Implement

ENS gives the business wallet and LendSignal agent a discoverable identity.

The ENS name is a lending gate, not a cosmetic label.

### Business Text Records

```text
lendsignal.certificate = <certificateId or registry pointer>
lendsignal.attestation = <attestationHash>
lendsignal.risk-tier = low_default_risk
lendsignal.agent = <LendSignal agent ENS name>
```

### Agent Text Records

Use ENSIP-26-style records:

```text
agent-context = JSON or Markdown describing the LendSignal credit agent
agent-endpoint[web] = https://<demo-url>/agent
agent-endpoint[mcp] = https://<demo-url>/mcp
```

Optional ENSIP-25-style verification:

```text
agent-registration[<registry>][<agentId>] = 1
```

### Frontend

Route:

```text
/ens
```

UI:

- input ENS name;
- resolve address;
- fetch text records;
- compare `lendsignal.attestation` to certificate registry;
- show pass/fail.

### Lending Gate

Approve only if:

```text
certificate active = true
certificate not expired = true
score >= threshold
ENS name resolves to borrower wallet
ENS text record matches certificate / attestation hash
```

## Feature 6: Lending Vault

### What We Implement

A lending vault that approves and pays out a working-capital loan when the certificate and ENS gate pass.

### Contract Shape

```solidity
contract LendingVault {
    IERC20 public asset;
    CreditCertificateRegistry public certificateRegistry;
    DefaultFund public defaultFund;

    uint256 public minScore = 750;
    uint256 public originationFeeBps = 300;

    function deposit(uint256 amount) external;
    function requestLoan(uint256 amount, string calldata ensName) external returns (uint256 loanId);
    function approveAndPayout(uint256 loanId) external;
}
```

### Approval Logic

```text
1. Read certificate from registry.
2. Verify active and unexpired.
3. Verify score >= 750.
4. Verify ENS gate.
5. Check vault liquidity.
6. Charge origination/default fund fee.
7. Transfer loan asset to borrower.
8. Create loan record.
```

## Feature 7: Uniswap Liquidity And Value Execution

### What We Implement

Use Uniswap API for core value movement in LendSignal.

Best hackathon integration:

```text
LP or borrower token
  -> Uniswap API quote/swap
  -> USDC or vault asset
  -> lending vault / default fund
```

### Uniswap API Flow

```text
1. /check_approval
2. /quote
3. /swap
4. user signs transaction
5. tx hash is stored and shown in demo
```

### Frontend

Route:

```text
/liquidity
```

UI:

- source token;
- amount;
- target: lending vault or default fund;
- Uniswap quote;
- expected output;
- slippage;
- submit swap;
- transaction hash.

### Where It Fits

Use Uniswap in two places:

1. **LP Deposit Conversion**
   - LP deposits WETH or another supported token.
   - Swap to USDC through Uniswap API.
   - Deposit USDC into DefaultFund.

2. **Borrower Fee Conversion**
   - Borrower pays origination fee in any supported token.
   - Swap fee to USDC.
   - Send USDC to DefaultFund.

### Demo Proof

Show transaction IDs for:

- token approval if needed;
- Uniswap swap;
- default fund deposit.

## Feature 8: Default Fund

### What We Implement

A default insurance pool that protects lenders.

### Contract Shape

```solidity
contract DefaultFund {
    IERC20 public asset;

    mapping(address => uint256) public lpBalances;

    function deposit(uint256 amount) external;
    function receiveBorrowerFee(uint256 amount) external;
    function reimburseDefault(uint256 loanId, address lender, uint256 amount) external;
}
```

### Demo Logic

For hackathon:

- default event is manually triggered by admin/demo controller;
- reimbursement transfers from DefaultFund to vault/lender;
- UI shows covered loan and reimbursement status.

## Feature 9: LendSignal Agent

### What We Implement

A simple agent-style service that exposes certificate status and lending recommendation.

The agent answers:

```text
Can this business wallet receive a loan?
What is the certificate status?
What risk tier is associated with it?
What vault policy applies?
```

MVP:

- `/agent/:ensName` read endpoint;
- JSON response with certificate status;
- ENS text records pointing to endpoint.

## Build Order

### Day 1 Morning

1. Scaffold frontend routes.
2. Create mock borrower profiles.
3. Build onboarding and certificate UI.
4. Implement CRS mock adapter.
5. Implement CreditCertificateRegistry.

### Day 1 Afternoon

1. Implement Chainlink Confidential AI adapter.
2. Implement mock fallback.
3. Add CRS mock bureau signal.
4. Add score combiner.
5. Issue certificate onchain.
6. Record tx hash.

### Day 2 Morning

1. Implement LendingVault.
2. Implement DefaultFund.
3. Add ENS resolver reads and text record verification.
4. Add vault payout flow.

### Day 2 Afternoon

1. Add Uniswap API swap flow.
2. Produce real swap tx.
3. Route converted assets to vault/default fund.
4. Polish sponsor-specific demo views.
5. Record 3-minute video.

## Demo Checklist

### CRS / Credit Bureau

- Submit business profile to mock CRS adapter.
- Show normalized bureau signal.
- Show bureau score included in final score.
- Show raw report hash stored offchain or in certificate metadata.

### Chainlink

- Submit Confidential AI inference request.
- Show request id and completed output.
- Show attestation hash.
- Show certificate issued onchain from result.
- Show CRE simulation if ready.

### ENS

- Enter ENS name.
- Resolve address.
- Fetch certificate/attestation text records.
- Verify ENS record matches onchain certificate.
- Show agent context or endpoint records.

### Uniswap

- Request quote through Uniswap API.
- Execute swap.
- Show tx hash.
- Deposit swapped asset into vault/default fund.
- Explain how Uniswap liquidity powers lending/default protection.

### Core Product

- Business onboarded.
- Certificate issued.
- ENS gate passed.
- Loan approved and paid out.
- Borrower fee routed.
- Default fund reimburses lender.

## Required Environment Variables

```text
NEXT_PUBLIC_CHAIN_ID=
NEXT_PUBLIC_RPC_URL=
PRIVATE_KEY=

CRS_API_BASE_URL=
CRS_API_CLIENT_ID=
CRS_API_CLIENT_SECRET=
CRS_API_USERNAME=
CRS_API_PASSWORD=
CRS_USE_MOCK=true

CHAINLINK_CONFIDENTIAL_AI_BASE_URL=https://confidential-ai-dev-preview.cldev.cloud
CHAINLINK_CONFIDENTIAL_AI_API_KEY=
CHAINLINK_CONFIDENTIAL_AI_MODEL=gemma4

UNISWAP_API_KEY=
UNISWAP_API_BASE_URL=

NEXT_PUBLIC_CERTIFICATE_REGISTRY=
NEXT_PUBLIC_LENDING_VAULT=
NEXT_PUBLIC_DEFAULT_FUND=

NEXT_PUBLIC_LENDSIGNAL_AGENT_ENS=
```

## References

- Chainlink CRE: https://docs.chain.link/cre
- Chainlink Confidential AI Attester demo: https://confidential-ai-dev-preview.cldev.cloud/docs
- CRS API docs: https://crscreditapi.redoc.ly/
- CRS Business Credit: https://crscreditapi.redoc.ly/developer-portal/business-credit/
- ENSIP-25: https://docs.ens.domains/ensip/25/
- ENSIP-26: https://docs.ens.domains/ensip/26/
- Uniswap API docs: https://developers.uniswap.org/docs/trading/swapping-api/getting-started
