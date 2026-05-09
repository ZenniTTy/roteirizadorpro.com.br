# Roteirizador Pro

Android route-planning app for delivery riders, distributed as APK from `roteirizadorpro.com.br`. Functional fork of [Spoke/Circuit Route Planner](https://getcircuit.com) with original visual identity, self-hosted infrastructure, and a planned 50/50 partner revenue split via Pix.

## Status

🟡 **In active development — Milestone 1**

| Milestone | Scope | Status |
|---|---|---|
| **M1** (BRL 2,000 / 30 days, deadline 2026-05-26) | Server (DO 1GB), landing page, backend auth API + healthchecks, GraphHopper SP graph, Login + Register Flutter screens | In progress |
| **M2** (BRL 2,000) | Post-M1 — scope to be reconfirmed with client. Original brief: Android APK, OCR/voice/optimization, Pix Split, paywall, admin panel | Not started |

Detailed roadmap: [`docs/08-ROADMAP.md`](./docs/08-ROADMAP.md).

## Architecture (one-liner)

Flutter app → Fastify API on DigitalOcean → GraphHopper (self-hosted) + PostgreSQL + Redis → Efí Bank Pix for subscriptions (M2).

Detail: [`docs/02-ARCHITECTURE.md`](./docs/02-ARCHITECTURE.md).

## UI source of truth

The Claude Design prototype at [`prototipo/`](./prototipo/) is the **canonical UI source** — client-approved 2026-05-07. Visual identity, screens, gestures, and flows must match it 1:1.

Documentation: [`docs/05-SCREENS.md`](./docs/05-SCREENS.md), [`docs/06-DESIGN-SYSTEM.md`](./docs/06-DESIGN-SYSTEM.md).

## Tech Stack

| Layer | Tech |
|---|---|
| Mobile | Flutter + Riverpod 3 |
| Backend | Node.js 20 + Fastify v5 + TypeBox |
| ORM / DB | Prisma 7 + PostgreSQL 16 |
| Cache | Redis 7 |
| Routing engine | GraphHopper (self-hosted, motorcycle profile) |
| Payments (M2) | Efí Bank API Pix v2 (mTLS, Split) |
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
├── TODO.md                  # Active M1 task list
├── apps/
│   ├── backend/             # Fastify API
│   ├── landing/             # Next.js landing page
│   └── mobile/              # Flutter app (auth screens for M1)
├── infra/                   # docker-compose, server provisioning
├── prototipo/               # Canonical UI source (Claude Design)
├── docs/
│   ├── 01-PROJECT.md
│   ├── 02-ARCHITECTURE.md
│   ├── 03-CONVENTIONS.md
│   ├── 04-FEATURES.md
│   ├── 05-SCREENS.md
│   ├── 06-DESIGN-SYSTEM.md
│   ├── 07-INFRA.md
│   ├── 08-ROADMAP.md
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
