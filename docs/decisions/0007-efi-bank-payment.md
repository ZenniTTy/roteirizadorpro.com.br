# ADR-0007: Use Efí Bank for Pix Payments with Native Split

- **Status:** ⚠️ **Superseded by [ADR-0030](./0030-stripe-pix-30-day-access-pass.md) on 2026-05-24** (gateway migrated to Stripe; charge model is now 30-day access pass, not monthly subscription). This document is preserved for historical context only — do NOT implement against it.
- **Date:** 2026-05-05
- **Deciders:** Eduardo, client
- **Supersedes:** Implicit Mercado Pago choice in original Workana proposal; also Primepag (which was rejected by client for poor support)

## Context

The product requires automated 50/50 revenue split between two business partners on every BRL 25.90 monthly subscription. Pix is the only payment method (no card support in V1). The split must happen at the moment of payment, not via post-hoc transfers. The client tested Primepag's support and was unsatisfied.

The client researched and selected Efí Bank (formerly Gerencianet) for: (a) responsive support, (b) native Pix Split via API, (c) competitive fees (1.19% + BRL 0.31 on BRL 25.90 = effective ~1.40 total).

## Options Considered

### Option A — Efí Bank Pix Split

- Pros: Native split feature; mTLS API auth (cert-based — no API key in headers); webhook system for event-driven activation; client validated their support quality; lower fees than card processors.
- Cons: No official Node.js SDK — must write direct HTTPS client with mTLS configured.

### Option B — Mercado Pago Marketplace API

- Pros: Original proposal choice; more mainstream; bigger marketing presence.
- Cons: Mercado Pago Marketplace integration is more complex; their fees are higher for our volume; client's prior experience was less favorable.

### Option C — Primepag

- Pros: Brazilian fintech with Pix-first approach.
- Cons: **Rejected by client** due to poor support response times.

### Option D — Stripe / Asaas / Other

- Pros: Various.
- Cons: Either no Pix Split native, or higher fees, or smaller Brazilian footprint. Not seriously considered.

## Decision

Use **Efí Bank Pix Split (API v2)** with mTLS authentication.

Implementation: direct HTTPS client (no SDK), one-time `POST /v2/gn/split/config` to register the 50/50 split between the two partner Efí accounts, then `PUT /v2/cob/:txid` + `PUT /v2/gn/split/cob/:txid/vinculo/:splitConfigId` per subscription cobrança. Webhook receiver at `/webhooks/efi/pix` validates HMAC and activates subscription.

## Consequences

- Positive: Automatic split at payment moment; no reconciliation work; clean fee structure; client-vetted support.
- Negative: Both partners must have approved Efí accounts (MEI or PJ) before M2 can ship; no SDK means we own the mTLS client; refunds are NOT supported on Efí Pix Split cobranças (must be disclosed in T&Cs).
- Neutral: Webhook idempotency is our responsibility (handled via `webhook_events` table and `e2e_id` deduplication).

## Implementation Notes

- Production endpoint: `https://pix.api.efipay.com.br`.
- Sandbox endpoint: `https://pix-h.api.efipay.com.br`.
- mTLS: `.p12` certificate downloaded from Efí dashboard. Stored on server at `/opt/roteirizador/certs/efi-prod.p12`, `chmod 600`, never in Git.
- Token endpoint: OAuth2 client credentials grant. Cache token until expiration.
- Both partner Efí accounts must be active before split config is registered.
- Webhook URL must be registered in Efí dashboard pointing to `https://api.roteirizadorpro.com.br/webhooks/efi/pix`.
- HMAC validation: Efí signs webhook payloads with a secret we configure. Validate every incoming webhook.

## References

- Efí Bank Pix Split docs: https://dev.efipay.com.br/docs/api-pix/split-de-pagamento-pix/
- Validation against Context7: `/websites/dev_efipay_br` (88 snippets, no official SDK confirmed).
