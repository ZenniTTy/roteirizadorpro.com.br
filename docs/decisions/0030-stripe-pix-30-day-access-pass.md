# ADR-0030: Migrate Pix gateway Efí Bank → Stripe + 30-day access pass model

- **Status:** Accepted
- **Date:** 2026-05-24
- **Deciders:** Eduardo, client
- **Supersedes:** ADR-0007 (Use Efí Bank for Pix Payments with Native Split)
- **Related ADRs:** ADR-0003 (Fastify backend — webhook endpoint moves), ADR-0015 (M2 plan — slice 4 scope shifts)
- **Sources of truth:** `docs/BUSINESS-RULES.md` (full operational rules), `docs/08-ROADMAP.md` §"Slice 4"

## Context

Client decision on 2026-05-24: migrate Pix gateway from Efí Bank to Stripe and revert from the short-lived "pay-per-route" model (introduced 2026-05-10) back to a recurring access model — implemented as a **30-day access pass renewed via fresh manual Pix payment** (not Stripe Billing subscriptions; Pix Automático is invite-only in Brazil).

Two changes folded into one ADR because they were decided together and only make sense as a pair.

## Decision

**Gateway:** Stripe (Connect platform, Separate Charges and Transfers for 50/50 split).
**Charge model:** single `PaymentIntent` for R$ 25,90 (2590 BRL cents); on `payment_intent.succeeded` webhook, backend grants 30 days of access (`subscription.status='active'`, `expires_at=now+30d`). No Stripe Billing, no recurring schedule, no Stripe Subscriptions API.
**Renewal:** when `expires_at` passes, the user must initiate a new manual Pix payment from inside the app. Daily cron at 03:00 BRT flips expired rows to `inactive`.
**Single paywall location:** "Iniciar Navegação" button on the optimized-route screen. Everything else is free forever.
**No cancellation, no refund, no automatic renewal** — these flows do not exist in the product or in the API. Codified in `BUSINESS-RULES.md` §8.

## Options Considered

| # | Option | Verdict |
|---|---|---|
| 1 | Keep Efí Bank + pay-per-route | Rejected — client decision; Stripe's Connect tooling + future Play Store path outweigh Efí's lower fees. |
| 2 | Stripe + Stripe Subscriptions (recurring billing) | Rejected — Pix Automático is invite-only in Brazil per official Stripe docs; "subscription" UX without recurring charge would mislead users. |
| 3 | Stripe + manual 30-day access pass (this ADR) | **Accepted.** Predictable UX, no surprise charges, single paywall point, Stripe Connect splits cleanly. |
| 4 | Stripe + Stripe Subscriptions with card fallback | Rejected — adds card flow the client explicitly excluded (Pix-only product). |

## Implementation summary

Detail lives in `docs/BUSINESS-RULES.md` (operational) + `docs/08-ROADMAP.md` §"Slice 4" (per-slice tasks). High-level:

- **Backend:** new `apps/backend/src/payments/` module — Stripe client, `PaymentIntent` creation, webhook handler at `POST /webhooks/stripe` (replaces `/webhooks/efi/pix`). Webhook validates `stripe.webhooks.constructEvent` signature, dedupes by `stripeEventId` in a `webhook_events` table (Prisma migration), executes split via two `stripe.transfers.create` calls to the two Connected Account IDs.
- **Mobile:** `PaywallController` reads `GET /subscription/status` from backend; UI shows price + QR code + copy-and-paste code from `payment_intent.next_action.pix_display_qr_code`. Polls `/subscription/status` every 5 s until active or modal closed.
- **Env vars (replace ADR-0007's Efí block):**
  ```
  STRIPE_SECRET_KEY=sk_live_...
  STRIPE_WEBHOOK_SECRET=whsec_...
  STRIPE_CONNECTED_ACCOUNT_SOCIO_1=acct_...
  STRIPE_CONNECTED_ACCOUNT_SOCIO_2=acct_...
  SUBSCRIPTION_AMOUNT_CENTS=2590
  SUBSCRIPTION_DURATION_DAYS=30
  ```
- **No mTLS, no `.p12` certificate** (those were Efí-specific). Stripe uses API key + webhook signing secret. ADR-0014 keystore custody is unaffected.

## Consequences

- **Fees move from 1,19% + R$ 0,31 (Efí) to ~1,5% + R$ 0,40 (Stripe Pix)** — net per partner drops from ~R$ 12,64 to ~R$ 12,56. Trade accepted by client for Connect tooling + future Play Store-friendly redirect path.
- **Pix Automático invite-only is non-issue today** — client's Stripe account already has Pix approval (confirmed 2026-05-24). If access is revoked in the future, this ADR is the rollback anchor.
- **Slice 4 estimate stays at 4–6 days.** Module structure is identical; only the SDK + webhook contract change.
- **ADR-0014** (keystore) untouched. **ADR-0017** (external navigation) untouched. Stack — Locked Versions in CLAUDE.md unaffected because Stripe is a runtime dep, added in slice 4's PR with the matching `package.json` bump + this ADR.

## Rollback

If Stripe Pix becomes unworkable (invite revoked, fees change unfavorably, Connect splits break):

1. New ADR-NNNN superseding this one — document the trigger and the new gateway choice.
2. Revert the `apps/backend/src/payments/` Stripe code; the Efí integration was never written (only specified in superseded ADR-0007 + old slice 4 doc), so there's no working alternative to fall back to — the new ADR must pick a replacement.
3. Update env vars + webhook URL in the Stripe dashboard (delete) and the new gateway's dashboard (configure).

## Verification (before slice 4 ships)

- [ ] Stripe sandbox: create `PaymentIntent` for 2590 BRL cents with Pix → confirm `next_action.pix_display_qr_code` returns.
- [ ] Stripe sandbox: simulate `payment_intent.succeeded` webhook → confirm signature validation passes, dedup by `stripeEventId` works, split transfers fire to both Connected Accounts.
- [ ] Subscription expires at `now+30d`; daily cron flips to `inactive` correctly.
- [ ] Mobile: paywall renders QR + copy-and-paste; polling unlocks "Iniciar Navegação" within 5 s of webhook arrival.
- [ ] `BUSINESS-RULES.md` §8 "inviolable" rules: no cancel endpoint, no refund endpoint, no recurring schedule — confirmed by `curl -X DELETE /subscription` returning 404 and absence of `stripe.subscriptions.*` calls in the codebase.

## References

- `docs/BUSINESS-RULES.md` — complete operational rules, paywall UX, "what does NOT exist" list, Play Store strategy.
- ADR-0007 — superseded by this ADR; kept for historical context on why Efí was the original choice.
- Stripe Pix docs (fetched 2026-05-24): `docs.stripe.com/payments/pix` — confirms Brazil availability, invite-only on Pix Automático, Connect split support via Separate Charges and Transfers.
- `docs/08-ROADMAP.md` §"Slice 4 — Stripe Pix 30-day access pass" — per-task plan (rewritten in this same PR).
