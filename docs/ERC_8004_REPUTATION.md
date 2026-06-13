# ERC-8004 Reputation Layer

## Why It Matters For LendSignal

ERC-8004 defines a trust framework for agents using three registries:

- Identity Registry;
- Reputation Registry;
- Validation Registry.

LendSignal can adapt this model to business wallets, curators, attesters and lending vaults.

The core idea:

```text
Wallet identity is not only an address.
It is a registered entity with metadata, attestations, feedback and validations.
```

## LendSignal Mapping

### Identity Registry

In ERC-8004, an agent gets an ERC-721 identity with an `agentId`, an `agentRegistry` and an `agentURI`.

In LendSignal:

- a business wallet can register a `borrowerId`;
- a curator can register a `curatorId`;
- an AI/confidential attester can register an `attesterId`;
- a lending vault can register a `vaultId`.

Each identity points to a metadata file.

Example borrower registration:

```json
{
  "type": "https://credsignal.xyz/schemas/borrower-registration-v1",
  "name": "Acme Imports LLC",
  "description": "Verified B2B borrower seeking working-capital credit.",
  "image": "ipfs://...",
  "services": [
    {
      "name": "ENS",
      "endpoint": "acme-imports.eth",
      "version": "v1"
    },
    {
      "name": "LendSignal",
      "endpoint": "https://app.credsignal.xyz/borrowers/123"
    }
  ],
  "active": true,
  "registrations": [
    {
      "agentId": 123,
      "agentRegistry": "eip155:8453:0xIdentityRegistry"
    }
  ],
  "supportedTrust": [
    "reputation",
    "tee-attestation",
    "credit-attestation"
  ]
}
```

## Reputation Registry

ERC-8004 lets clients post feedback to an agent using:

- numeric value;
- decimals;
- optional tags;
- endpoint;
- feedback URI;
- feedback hash.

LendSignal can use this for credit and operating reputation.

Example feedback tags:

```text
repayment
invoicePaid
onTimePayment
kybVerified
creditworthiness
vaultPerformance
defaultEvent
documentAuthenticity
```

Example feedback:

```json
{
  "agentRegistry": "eip155:8453:0xIdentityRegistry",
  "agentId": 123,
  "clientAddress": "eip155:8453:0xLendingVault",
  "createdAt": "2026-06-13T00:00:00Z",
  "value": 100,
  "valueDecimals": 0,
  "tag1": "repayment",
  "tag2": "loan_001",
  "endpoint": "https://api.credsignal.xyz/passports/cp_001",
  "proofOfPayment": {
    "fromAddress": "0xBorrower",
    "toAddress": "0xVault",
    "chainId": "8453",
    "txHash": "0x..."
  }
}
```

## Validation Registry

ERC-8004 also supports independent validation requests and responses.

LendSignal can use validation for:

- verifying AI credit attestations;
- validating curator attestations;
- checking whether a borrower document hash matches the private evidence set;
- validating no-default claims;
- validating vault performance.

Example validation request:

```json
{
  "requestType": "credit_attestation_validation",
  "passportId": "cp_001",
  "aiCreditAttestationId": "att_ai_001",
  "borrowerAgentId": 123,
  "evidenceHash": "0x...",
  "score": 820,
  "riskTier": "low_default_risk"
}
```

Example validation response:

```json
{
  "requestHash": "0x...",
  "response": 100,
  "tag": "tee-attestation-valid",
  "responseURI": "ipfs://...",
  "responseHash": "0x..."
}
```

## Wallet Reputation Score

LendSignal can compute a wallet reputation score from ERC-8004-style signals:

```text
Wallet Reputation Score =
  repayment feedback
  + verified curator feedback
  + validation results
  + onchain financial behavior
  - default events
  - revoked or disputed feedback
  - risky exposure flags
```

For MVP:

```text
repayment: 35%
credit attestation validation: 25%
KYB/business verification: 15%
invoice/payment history: 15%
onchain wallet behavior: 10%
```

This score is separate from the Creditworthiness Score:

- Creditworthiness Score answers: "Can this business safely receive credit now?"
- Wallet Reputation Score answers: "Has this wallet/entity behaved reliably over time?"

Together they make underwriting stronger.

## MVP Implementation

For the hackathon, we do not need a full ERC-8004 implementation.

Build a compatible simulator:

1. Create local mock identities for borrower, curator, attester and vault.
2. Assign each one an `agentId`, `agentRegistry` and metadata URI.
3. Generate feedback entries with tags like `repayment`, `kybVerified` and `creditworthiness`.
4. Generate validation responses for AI attestations.
5. Display a Wallet Reputation Score beside the Creditworthiness Score.
6. Let the lending vault use both scores.

Example vault policy:

```text
Approve best terms when:
  Creditworthiness Score >= 800
  Wallet Reputation Score >= 85
  no default feedback
  AI attestation validation >= 90
  passport is not revoked
```

## Product Positioning

LendSignal can say:

```text
We use an ERC-8004-inspired identity, reputation and validation model to turn a business wallet into a credit-bearing entity.
```

This is stronger than saying the app "scores a wallet." It says LendSignal creates a portable trust object that protocols can discover, verify and reuse.
