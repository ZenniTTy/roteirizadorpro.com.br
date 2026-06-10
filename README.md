# Roteirizador Pro

Android route-planning app for delivery riders, distributed as APK from `roteirizadorpro.com.br`. Functional fork of [Spoke/Circuit Route Planner](https://getcircuit.com) with original visual identity, self-hosted infrastructure, and a planned 50/50 partner revenue split via Pix.

## Status

🟡 **In active development — M2, Slice 2 (Telas Core Spoke-aligned, ~55%).** M1 closed 2026-05-09.

| Milestone | Scope | Status |
|---|---|---|
| **M1** (BRL 2,000) | Server (DO), landing page, backend auth API + healthchecks, GraphHopper SP graph, Login + Register Flutter screens, APK `v1.0.0` | Delivered 2026-05-09 |
| **M2** (BRL 2,000) | 7 slices locked per `docs/08-ROADMAP-v2.md`: Telas Core, backend real, Pix paywall, sentido casa, LGPD, admin | In progress (Slice 2 active) |

Detailed roadmap: [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md) (v1 archived 2026-05-26 to `docs/archive/` per [ADR-0035](./docs/decisions/0035-spoke-functional-clone-prototype-creative-reference.md)).

## Architecture (one-liner)

Flutter app → Fastify API on DigitalOcean → GraphHopper (self-hosted) + PostgreSQL + Redis → Stripe Pix + Connect 50/50 split for the 30-day access pass (M2).

Detail: [`docs/02-ARCHITECTURE.md`](./docs/02-ARCHITECTURE.md).

## Source-of-truth hierarchy (ADR-0035)

Two artifacts, each canonical only for what it is authoritative on:

- **Spoke (ex-Circuit Route Planner)** — canonical for **behavior**: screens, navigation, settings, feature presence, gestures, flow ordering. The end-user is a delivery rider who already uses Spoke daily; functional parity is the contract.
- **[`prototipo/`](./prototipo/) (Claude Design prototype)** — canonical for **visual identity only**: color tokens (`tokens.js`), spacing scale, radii, shadows, typography, icon family (Lucide), animations.
- **Cliente Ueslei** — final tiebreaker. Per [ADR-0010](./docs/decisions/0010-clone-positioning.md), the cliente is the contracting authority.

Per [ADR-0010](./docs/decisions/0010-clone-positioning.md) (functional fork positioning) and [ADR-0035](./docs/decisions/0035-spoke-functional-clone-prototype-creative-reference.md) (this hierarchy): replicate Spoke's *functionality*; never replicate its *visual assets*.

Documentation: [`docs/inventory/2026-05-26-spoke-vs-rotpro.md`](./docs/inventory/2026-05-26-spoke-vs-rotpro.md) (canonical Spoke↔RotPro catalogue — paraphrase), [`docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md`](./docs/inventory/spoke-dump-v3.65.1/MASTER-TABLE.md) (static dump of Spoke v3.65.1 — the structural baseline of FACT, read first per [ADR-0045](./docs/decisions/0045-spoke-static-dump-baseline.md)), [`docs/06-DESIGN-SYSTEM.md`](./docs/06-DESIGN-SYSTEM.md).

## Tech Stack

| Layer | Tech |
|---|---|
| Mobile | Flutter + Riverpod 3 |
| Backend | Node.js 20 + Fastify v5 + TypeBox |
| ORM / DB | Prisma 7 + PostgreSQL 16 |
| Cache | Redis 7 |
| Routing engine | GraphHopper (self-hosted, motorcycle profile) |
| Payments (M2) | Stripe Pix + Stripe Connect 50/50 split (ADR-0030) |
| Landing | Next.js 14 on Vercel |
| Server | Ubuntu 24.04 on DigitalOcean (client's account) |

Locked versions and rationale: [`docs/decisions/`](./docs/decisions/).

## Repository Structure

```
.
├── CLAUDE.md                # Operating manual for AI agents (READ FIRST)
├── CONTRIBUTING.md          # Git workflow, commit format, branching
├── README.md                # You are here
├── SECURITY.md              # Security policy
├── TODO.md                  # Active M2 slice task list
├── apps/
│   ├── backend/             # Fastify API
│   ├── landing/             # Next.js landing page
│   └── mobile/              # Flutter app (auth + drawer + wizard + route shell + add-stop + route-details)
├── infra/                   # docker-compose, server provisioning
├── prototipo/               # Visual identity source (Claude Design — tokens, ícones Lucide, paleta)
├── docs/
│   ├── 01-PROJECT.md
│   ├── 02-ARCHITECTURE.md
│   ├── 03-CONVENTIONS.md
│   ├── 04-FEATURES.md
│   ├── 06-DESIGN-SYSTEM.md
│   ├── 07-INFRA.md
│   ├── 08-ROADMAP-v2.md         # active M2 plan (simplified post-reset 2026-05-26)
│   ├── 09-DISASTER-RECOVERY.md
│   ├── 10-CHANGELOG.md
│   ├── decisions/           # ADRs
│   ├── sessions/            # AI session logs
│   └── superpowers/         # Specs and plans
└── scripts/                 # Repo-level utilities
```

## For AI Agents

If you are an AI agent (Claude Code, Cursor, Claude web), **start by reading [`CLAUDE.md`](./CLAUDE.md) in full**. It is the operating manual for this repository.

## For Humans

- Project owner: Eduardo Rodrigues — `eduardo@ianelli.tech`
- Workana proposal: M1 + M2 = BRL 4,000 (escrow, milestone-based)

## License

Proprietary. All rights reserved by the project owner and the client.
