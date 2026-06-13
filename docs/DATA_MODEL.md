# Data Model

## BusinessProfile

```typescript
type BusinessProfile = {
  id: string;
  wallet: string;
  legalName: string;
  country: string;
  industry: string;
  requestedLoanUsd: number;
  requestedPurpose: 'working_capital' | 'inventory' | 'payroll' | 'receivables' | 'growth';
  kycStatus: 'not_started' | 'pending' | 'passed' | 'failed';
  kybStatus: 'not_started' | 'pending' | 'passed' | 'failed';
  createdAt: string;
};
```

## Curator

```typescript
type Curator = {
  id: string;
  name: string;
  curatorType: 'kyb' | 'credit' | 'banking' | 'invoice' | 'onchain' | 'identity' | 'aml' | 'deco';
  walletAddress: string;
  publicKey: string;
  serviceUri: string;
  supportedSignals: string[];
  reputationScore: number;
  status: 'active' | 'paused' | 'revoked';
};
```

## BorrowerDocument

```typescript
type BorrowerDocument = {
  id: string;
  borrowerWallet: string;
  documentType:
    | 'financial_statement'
    | 'tax_return'
    | 'bank_statement'
    | 'accounts_receivable_aging'
    | 'accounts_payable_aging'
    | 'inventory_listing'
    | 'debt_schedule'
    | 'legal_document';
  fileHash: string;
  encryptedUri?: string;
  periodStart?: string;
  periodEnd?: string;
  status: 'pending' | 'processed' | 'rejected';
};
```

## ConfidentialAIRequest

```typescript
type ConfidentialAIRequest = {
  id: string;
  model: 'gemma4' | 'qwen3.6';
  businessProfileId: string;
  prompt: string;
  resourceIds: string[];
  status: 'queued' | 'preparing-resources' | 'processing' | 'completed' | 'failed';
  output?: string;
  error?: string;
  createdAt: string;
  completedAt?: string;
};
```

## CreditBureauSignal

```typescript
type CreditBureauSignal = {
  provider: 'crs_mock' | 'crs';
  reportId: string;
  businessProfileId: string;
  businessWallet: string;
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

## CreditCertificate

```typescript
type CreditCertificate = {
  id: string;
  businessWallet: string;
  businessProfileId: string;
  confidentialAiScore: number;
  bureauScore: number;
  creditBureauSignalId?: string;
  walletBehaviorScore: number;
  combinedScore: number;
  riskTier: 'low_default_risk' | 'medium_default_risk' | 'high_default_risk';
  status: 'pending' | 'active' | 'expired' | 'updated' | 'revoked' | 'defaulted';
  attestationHash: string;
  evidenceDigest: string;
  ensName?: string;
  issuedAt: string;
  expiresAt: string;
  lastUpdatedAt: string;
};
```

## ReputationIdentity

```typescript
type ReputationIdentity = {
  agentId: number;
  agentRegistry: string;
  ownerWallet: string;
  agentURI: string;
  identityType: 'borrower' | 'curator' | 'attester' | 'vault';
  active: boolean;
};
```

## ReputationFeedback

```typescript
type ReputationFeedback = {
  agentId: number;
  clientAddress: string;
  value: number;
  valueDecimals: number;
  tag1:
    | 'repayment'
    | 'invoicePaid'
    | 'kybVerified'
    | 'creditworthiness'
    | 'vaultPerformance'
    | 'defaultEvent'
    | 'documentAuthenticity';
  tag2?: string;
  endpoint?: string;
  feedbackURI?: string;
  feedbackHash?: string;
  revoked: boolean;
  createdAt: string;
};
```

## ValidationResponse

```typescript
type ValidationResponse = {
  requestHash: string;
  validatorAddress: string;
  agentId: number;
  response: number;
  responseURI?: string;
  responseHash?: string;
  tag:
    | 'tee-attestation-valid'
    | 'curator-attestation-valid'
    | 'document-evidence-valid'
    | 'repayment-verified';
  lastUpdate: string;
};
```

## FinancialMetrics

```typescript
type FinancialMetrics = {
  borrowerWallet: string;
  currentRatio: number;
  quickRatio: number;
  dscr: number;
  ebitdaUsd: number;
  cashBurnMonths: number;
  revenueGrowth: 'negative' | 'flat' | 'positive' | 'high_growth';
  leverageRatio: number;
  receivablesConcentration: number;
  cashflowVolatility: 'low' | 'medium' | 'high';
  sourceDocumentHashes: string[];
};
```

## Attestation

```typescript
type Attestation = {
  id: string;
  subject: string;
  subjectType: 'wallet' | 'business' | 'person' | 'agent';
  signalType: string;
  result: string;
  confidence: number;
  issuedAt: string;
  expiresAt: string;
  curatorId: string;
  signature: string;
  evidenceHash?: string;
};
```

## AICreditAttestation

```typescript
type AICreditAttestation = {
  id: string;
  subject: string;
  subjectType: 'business_wallet';
  signalType: 'creditworthiness_score';
  score: number;
  riskTier: 'low_default_risk' | 'medium_default_risk' | 'high_default_risk';
  summary: string;
  metrics: FinancialMetrics;
  evidenceHash: string;
  computeProof: string;
  attester: string;
  issuedAt: string;
  expiresAt: string;
  signature: string;
};
```

## WalletSignal

```typescript
type WalletSignal = {
  wallet: string;
  walletAgeDays: number;
  stablecoinVolumeUsd: number;
  lendingProtocolsUsed: string[];
  borrowCount: number;
  repaymentCount: number;
  liquidationCount: number;
  riskFlags: string[];
};
```

## CreditPassport

```typescript
type CreditPassport = {
  id: string;
  subject: string;
  subjectType: 'wallet' | 'business';
  reputationIdentity?: ReputationIdentity;
  creditworthinessScore: number;
  walletReputationScore: number;
  defaultRiskTier: 'low' | 'medium' | 'high';
  walletRiskScore: number;
  creditReliabilityScore: number;
  businessTrustScore: number;
  creditTier: 'A' | 'A-' | 'B+' | 'B' | 'C' | 'D';
  suggestedCreditLineUsd: number;
  suggestedCollateralRequiredPct: number;
  collateralAdjustmentBps: number;
  attestations: string[];
  aiCreditAttestationId: string;
  ensPointer?: string;
  defaultFundEligible: boolean;
  validUntil: string;
  revoked: boolean;
};
```

## ProtocolDecision

```typescript
type ProtocolDecision = {
  protocolId: string;
  wallet: string;
  passportId: string;
  decisionType: 'credit_line' | 'collateral_discount' | 'lp_access' | 'risk_limit' | 'vault_loan';
  beforeTerms: Record<string, unknown>;
  afterTerms: Record<string, unknown>;
  reasonCodes: string[];
  createdAt: string;
};
```

## DefaultFundPosition

```typescript
type DefaultFundPosition = {
  id: string;
  vaultId: string;
  passportId: string;
  coveredLoanUsd: number;
  coverageRatioPct: number;
  reserveFeeBps: number;
  status: 'active' | 'claimed' | 'expired';
};
```
