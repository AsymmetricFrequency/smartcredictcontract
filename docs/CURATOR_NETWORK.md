# Curator Network

## Concept

LendSignal is powered by curators and confidential attesters.

Curators are trusted data providers that verify signals and issue signed attestations.

Confidential attesters analyze sensitive borrower data and produce verifiable score attestations without publishing raw documents.

LendSignal does not need to own every data source. It coordinates and standardizes curator and attester output.

## Curator Categories

### Credit Data Curators

Examples:

- consumer credit data providers;
- business credit providers;
- credit monitoring platforms;
- business registry data services.

Signals:

- credit band;
- default risk;
- business credit tier;
- credit history freshness.
- no major defaults reported.

### Identity Curators

Examples:

- KYC providers;
- KYB providers;
- World ID;
- business registry verification;
- authorized signer verification.

Signals:

- person verified;
- business verified;
- authorized signer;
- jurisdiction.

### Financial Curators

Examples:

- open banking providers;
- accounting platforms;
- payment processors;
- merchant revenue platforms.

Signals:

- revenue band;
- cashflow consistency;
- account age;
- transaction volume.
- bank balance threshold proof.
- debt payment consistency.

### Invoice Curators

Examples:

- invoice platforms;
- accounting systems;
- B2B payment platforms;
- supplier networks.

Signals:

- invoice paid;
- invoice disputed;
- invoice aging;
- supplier reliability.
- receivables quality.
- payment delay frequency.

### Onchain Curators

Examples:

- blockchain analytics providers;
- lending protocol indexers;
- stablecoin flow analytics;
- risk engines.

Signals:

- liquidation history;
- repayment behavior;
- wallet age;
- stablecoin volume;
- risky exposure.

### AML And Sanctions Curators

Examples:

- AML screening services;
- sanctions list providers;
- compliance data APIs;
- fraud monitoring providers.

Signals:

- sanctions exposure;
- AML risk tier;
- adverse media flag;
- fraud pattern flag.

### DECO-Style Fact Curators

Examples:

- privacy-preserving API verifiers;
- bank balance threshold verifiers;
- tax authority confirmation connectors;
- business registry fact verifiers.

Signals:

- fact verified;
- threshold satisfied;
- source freshness;
- proof metadata.

### Confidential AI Attesters

Examples:

- Chainlink Confidential AI Attester-style workflow;
- TEE-based scoring service;
- private document analysis engine.

Signals:

- Creditworthiness Score;
- default-risk tier;
- financial metric summary;
- fraud/tampering checks;
- compute proof metadata;
- evidence hash.

## Curator Business Model

Curators earn when their attestations are used.

Flow:

1. Protocol requests a signal.
2. LendSignal queries eligible curators.
3. Borrower authorizes private document analysis if needed.
4. Curator or attester issues an attestation.
5. Protocol consumes passport.
6. Fee is split between curator, attester and LendSignal.

## Curator Incentives

Curators benefit from:

- new distribution channel;
- usage-based revenue;
- onchain reputation;
- protocol integrations;
- standardized attestation format.

## Curator Registry

Possible onchain registry:

```solidity
struct Curator {
    address curator;
    string metadataURI;
    bytes32[] supportedSignals;
    bool active;
}
```

## Attester Registry

Possible onchain registry:

```solidity
struct Attester {
    address attester;
    string metadataURI;
    bytes32[] supportedWorkflows;
    bool confidentialCompute;
    bool active;
}
```

## Trust Controls

Curators and attesters can be:

- approved;
- staked;
- rated;
- challenged;
- revoked.

Bad attestations can reduce curator reputation.
