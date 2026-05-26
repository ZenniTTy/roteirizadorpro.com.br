# Session 23 — Pix gateway migration: Efí Bank → Stripe + 30-day access pass

## Metadata

- **Date**: 2026-05-24 (America/Sao_Paulo)
- **Sequence**: 23 (first session after PR #8 merge of M2-AI harness sprint)
- **Agent**: Claude Code (Opus 4.7)
- **Human**: Eduardo
- **Topic**: Reconcile all canonical + hot-path docs to the Stripe + 30-day-access-pass decision; file ADR-0030
- **Duration**: ~50m
- **Related ADRs**: ADR-0030 (new), ADR-0007 (superseded by 0030), ADR-0015 (cross-ref annotated)
- **Related TODO items**: none active; this work created `BUSINESS-RULES.md` as the operational source-of-truth alongside ADR-0030

## Goal

Client decided (late 2026-05-24) to:
1. Replace **Efí Bank** Pix gateway with **Stripe** (Stripe Connect + Separate Charges and Transfers for 50/50 split).
2. Revert the brief 2026-05-10 "pay-per-route" experiment back to a **30-day access pass** model — R$ 25,90 per pass, **manually renewed** by a new Pix payment when the period expires (no Stripe Subscriptions, no Stripe Billing; Pix Automático is invite-only in BR).

Eduardo authored `docs/BUSINESS-RULES.md` (commit `cc1b546`) capturing the operational rules. This session's job: file the formal ADR + reconcile every other canonical document so a fresh session finds zero contradictions.

## What was done

**Decision documents**
- Filed **ADR-0030** (`docs/decisions/0030-stripe-pix-30-day-access-pass.md`) under the enxuto pattern (~85 lines): frontmatter + Context + Decision + 4-row Options table + Implementation summary + Consequences + Rollback + Verification + References. Supersedes ADR-0007.
- **ADR-0007** marked `Superseded by ADR-0030` in the header banner; body preserved unchanged for historical context.
- **ADR-0015** `Related ADRs` line annotated to mark ADR-0007 as superseded; body untouched.
- **ADR-0003** intentionally NOT touched — its Efí Bank mention was true at 2026-05-05 decision time; rewriting it would falsify history.

**Six canonical docs reconciled in the same PR**
- `CLAUDE.md` — slice 4 row + Last updated.
- `docs/01-PROJECT.md` — monetization section (model, fees, Stripe Connect, Play Store strategy pointer).
- `docs/02-ARCHITECTURE.md` — Flow 3 (10-step Stripe Pix flow, idempotency, 30-day grant, renewal), payment subsystem (Stripe SDK, no mTLS), DB schema (subscriptions + payments + webhook_events with stripe_payment_intent_id + stripe_event_id), API endpoint list, security note.
- `docs/04-FEATURES.md` — F09 (30-day access pass paywall) + F10 (Stripe Pix + Connect split). F11 stays removed with new rationale (no MRR in 30-day-pass model; admin panel F13 shows DAU + payments-in-period).
- `docs/08-ROADMAP.md` — Slice 4 section fully rewritten (Stripe prereqs replacing Efí prereqs, implementation outline, file tree, fee note, "forbidden in this slice" block referencing BUSINESS-RULES §8). KPI label changed MRR → receita-30-dias. Cost line updated.
- `docs/M2-COST-MODEL.md` — Pix transaction row updated (~1,5% + R$ 0,40, ~R$ 0,79 per charge, ~R$ 12,56 net per partner). Cost tracking pointer updated to Stripe Dashboard.

**Hot-path docs swept** (read on every onboarding)
- `README.md` (architecture one-liner + tech stack table).
- `PROJECT-CONTEXT.md` (business model + tech table + critical decisions + infra access).
- `TODO.md` slice 4 entry (Stripe prereqs replace Efí .p12/HMAC).
- `SECURITY.md` (Stripe webhook signature validation replaces Efí HMAC).
- `docs/Blueprint.md` (pricing/payment rows + payment gateway row + payments module purpose + integrations table + open question #7 about partner accounts; open question #6 about WebSocket marked as F11-removed).
- `docs/03-CONVENTIONS.md` env var example.
- `docs/07-INFRA.md` M2 secrets inventory (Stripe env vars replace Efí ones).
- `docs/09-DISASTER-RECOVERY.md` Scenario 6 (Stripe outage) + Scenario 7 (rotate STRIPE_SECRET_KEY + STRIPE_WEBHOOK_SECRET).
- `docs/INSTALL.md` `certs/` note (Stripe needs no cert).
- `docs/BUSINESS-RULES.md` got `Status: Accepted` + ADR-0030 cross-ref + a clarification block: "R$ 25,90 por mês" no marketing/UI = "R$ 25,90 a cada renovação manual de 30 dias" — there is no automatic monthly charge.

**Changelog** — `docs/10-CHANGELOG.md` got a full entry covering the pass.

**Pipeline** — `adr-guardian` run before commit returned GREEN, zero BLOCKING items. No `pubspec.yaml` / `package.json` / `infra/` / `prisma/` was touched this turn (Stripe SDK and the schema migration land when slice 4 actually starts). lefthook + commitlint passed without `--no-verify`.

**Commit:** `68c258c` — `docs: migrate Pix gateway from Efí Bank to Stripe + 30-day access pass (ADR-0030)`. 20 files, +298 / −178.

## Decisions made

1. **One commit, not staged across phases.** Reconciliation has no incremental value — until every doc is consistent, the branch ships ambiguity. A single commit means the reader either sees pre-Stripe or post-Stripe, never partial.
2. **ADR-0007 stays Superseded, not deleted.** Preserves "why we originally chose Efí" for any future similar decision.
3. **ADR-0003 body untouched.** The "no Efí Node SDK" rationale was correct at 2026-05-05; deleting it would falsify the decision context. Future ADRs can reference its conclusion (Fastify) without re-litigating it.
4. **Session logs / briefing / superpowers older specs untouched.** Same immutability principle.
5. **Cross-refs to "ADR-0007 (Efí Bank)" kept as "superseded by ADR-0030".** Rastreabilidade — anyone tracing history needs the link.

## Self-audit findings (caught after the commit, fixed in next commit)

I committed before doing the self-audit. Three real issues surfaced when the owner pressed "did you follow best practices?":

1. **Session End Protocol violated** — I shipped 20-file commit without a session log. CLAUDE.md is explicit: "Create `docs/sessions/YYYY-MM-DD-NN-<topic>.md`. Append the new session to `docs/sessions/0001-INDEX.md`." This very file fixes it post-hoc. Lesson: session log is not "nice to have when it's code work" — it applies to **any meaningful session**, including 20-doc reconciliation passes.
2. **Onboarding Ritual bullet #10** said "ADRs 0023–0029 cover the AI harness" — true, but doesn't mention ADR-0030 exists. A fresh session reading the Onboarding Ritual would miss the Stripe context. Fixed in next commit.
3. **ADR-0030 §Context** had a slightly imprecise phrase ("revert to a recurring access model") — "recurring" suggests automatic recurrence which is exactly what we explicitly do NOT do. Fixed in next commit to "30-day access pass model renewed via fresh manual Pix on each cycle."
4. **WebSocket residual** — F11 was removed but `docs/04-FEATURES.md` F11 section still describes a `WS /ws/stats` endpoint, and `docs/02-ARCHITECTURE.md` lists `web_socket_channel` in the mobile package set + WS in the architecture diagram. Slice 4 uses polling (5 s) per ADR-0030, not WebSocket. Stale references would mislead the slice-4 implementer into installing `web_socket_channel` unnecessarily. Fixed in next commit.

## Files changed (this session, the migration commit + the audit-pass commit)

**Migration commit `68c258c` (20 files, +298 / −178):**

Created:
- `docs/decisions/0030-stripe-pix-30-day-access-pass.md`

Modified:
- ADRs: `0007-efi-bank-payment.md` (header banner), `0015-m2-plan-and-libraries.md` (Related ADRs line).
- Hot path: `CLAUDE.md`, `README.md`, `PROJECT-CONTEXT.md`, `TODO.md`, `SECURITY.md`.
- Canonical M2 docs: `docs/{01-PROJECT,02-ARCHITECTURE,04-FEATURES,07-INFRA,08-ROADMAP,09-DISASTER-RECOVERY,10-CHANGELOG,M2-COST-MODEL,BUSINESS-RULES,Blueprint,INSTALL,03-CONVENTIONS}.md`.

**Audit-pass commit (next, this turn):**

Created:
- `docs/sessions/2026-05-24-23-stripe-migration.md` (this file).

Modified:
- `docs/sessions/0001-INDEX.md` — entry added at top.
- `CLAUDE.md` — Onboarding Ritual bullet #10 updated to cover post-M1 ADRs through 0030.
- `docs/decisions/0030-stripe-pix-30-day-access-pass.md` — §Context phrasing fix ("30-day access pass model renewed via fresh manual Pix").
- `docs/04-FEATURES.md` — F11 WebSocket residual removed (F11 already marked removed in the feature table).
- `docs/02-ARCHITECTURE.md` — `web_socket_channel` removed from mobile-package list; "Cache, WS" → "Cache" in architecture diagram.

## What did NOT happen, and why

- **No Stripe SDK installed in `apps/backend/package.json`.** That belongs to slice 4's implementation PR — this session is documentation-only.
- **No `apps/backend/prisma/schema.prisma` migration.** Same reason.
- **No code touched in `apps/mobile/`.** Slice 4 will write the `PaywallController` + paywall page; this session sets the spec for that work.

## Practical impact (plain language)

A migração do gateway Efí Bank → Stripe ficou documentada de ponta a ponta em **20 arquivos no commit principal + correções deste audit log em mais um commit**. Quando você (ou outra sessão) abrir a slice 4 lá na frente, vai ler:

- ADR-0030 (a decisão técnica + opções consideradas)
- BUSINESS-RULES.md (regras de negócio do cliente)
- 08-ROADMAP §"Slice 4" (passo-a-passo de implementação)
- 02-ARCHITECTURE Flow 3 (sequência completa de eventos)

E os 4 documentos vão dizer **a mesma coisa**. Sem contradição, sem "Efí" caindo de surpresa em alguma section esquecida.

**O modelo agora:** R$ 25,90 paga 30 dias de acesso. Não é assinatura recorrente. Não é Stripe Billing. Quando os 30 dias acabam, o usuário paga de novo manualmente — Stripe envia o webhook, backend renova por mais 30 dias. Split 50/50 vai automático pros dois sócios via Stripe Connect.

**Erro que eu cometi (e estou consertando aqui):** commitei a migração sem session log + sem atualizar Onboarding Ritual + com 2 detalhes ambíguos (WebSocket residual + frase "recurring access model" na ADR). Você pressionou "seguiu boas práticas?" e o audit honesto pegou. Próxima vez, session log é parte do commit, não pós-hoc.
