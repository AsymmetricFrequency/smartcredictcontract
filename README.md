# LendSignal

LendSignal is an onchain credit certification and lending demo for growth-stage businesses in emerging markets.

It helps a business turn its wallet into a credit identity by submitting business information, documents and KYC/KYB-style data through a confidential verification flow. Lending vaults can then use the resulting Credit Certificate to approve working-capital loans.

## One-Liner

LendSignal turns business documents, KYC/KYB evidence and wallet behavior into an updateable onchain Credit Certificate that lending pools can use to issue undercollateralized working-capital loans.

## Why It Matters

Onchain finance is still mostly overcollateralized because protocols see addresses, not the financial health of the business behind those addresses.

A business may have strong cashflow, clean repayment behavior, verified revenue, invoices and legal standing, but most protocols cannot consume that context safely.

LendSignal lets a borrower submit sensitive business data into a confidential workflow. A Chainlink Confidential AI Attester-style process analyzes the supplied data and returns a structured result, which is combined with 3rd party bureau and wallet-behavior signals.

Raw documents stay private. The public/onchain layer only exposes the certificate status, score, risk tier, attestation hash, evidence digest and ENS gate status.

## Core Users

- Lending protocols.
- Stablecoin credit products.
- Invoice financing platforms.
- Liquidity provider networks.
- B2B payment and merchant-financing platforms.
- Working-capital vault managers.

## 48-Hour MVP

The hackathon MVP builds four connected features:

1. **Business Onboarding**
   - Business connects wallet.
   - Business submits mock company information.
   - Business uploads/selects mock documents.
   - Wallet becomes the business credit identity.

2. **Credit Worthiness Score**
   - Mock Confidential AI Attester score.
   - Mock CRS credit bureau score.
   - Optional wallet-behavior signal.
   - Combined score from `0-1000`.
   - Public output: score, risk tier and attestation hash.

3. **Credit Certificate And Loan Payout**
   - Store an updateable Credit Certificate for the business wallet.
   - Fork or simulate a collateralized lending protocol.
   - Replace collateral-only approval with score-based approval.
   - Gate each loan deployment by ENS record status.
   - Automatically pay out the loan when checks pass.

4. **Reimburse Lenders For Default Loans**
   - LPs deposit into a decentralized insurance/default pool.
   - Borrower fees reward LPs.
   - If a loan defaults, the default fund reimburses lenders.

## Hackathon Demo

The demo flow shows:

1. A borrower connects a business wallet.
2. The business submits mock business information and documents.
3. LendSignal sends the evidence through a Confidential AI Attester-style flow.
4. LendSignal combines the AI result with bureau and wallet-behavior signals.
5. LendSignal emits or stores an updateable Credit Certificate for the wallet.
6. The lending vault checks certificate status, score, ENS gate and liquidity.
7. If approved, the vault automatically pays out the loan.
8. Borrower fees flow into the default fund.
9. LPs can reimburse lenders when a loan defaults.

## Repository Structure

```text
hackathon-credsignal/
├── artifacts/
│   ├── LendSignal_Credit_Certificate_Brief.docx
│   ├── LendSignal_Credit_Certificate_Brief.pdf
│   ├── LendSignal_User_Data_Flow.docx
│   └── LendSignal_User_Data_Flow.pdf
├── scripts/
│   ├── build_concept_brief.py
│   └── build_user_data_flow_pdf.py
├── README.md
└── docs/
    ├── ARCHITECTURE.md
    ├── BUSINESS_PROPOSAL.md
    ├── CHAINLINK_CRE_WORKFLOW.md
    ├── CREDIT_CERTIFICATION_FLOW.md
    ├── CURATOR_NETWORK.md
    ├── DATA_MODEL.md
    ├── DEMO_SCRIPT.md
    ├── ERC_8004_REPUTATION.md
    ├── FEATURE_IMPLEMENTATION_PLAN.md
    ├── HACKATHON_48H_SCOPE.md
    ├── MVP_SPEC.md
    ├── SMART_CONTRACT_ARCHITECTURE.md
    ├── USER_DATA_FLOW.md
    └── WIREFRAMES.md
```
