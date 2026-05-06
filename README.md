# Roteirizador Pro

Android route-planning app for delivery riders, distributed as APK from `roteirizadorpro.com.br`. Functional fork of [Circuit Route Planner](https://getcircuit.com) with original visual identity, self-hosted infrastructure, and 50/50 partner revenue split via Pix.

## Status

🟡 **In active development — Milestone 1**

| Milestone | Scope | Status |
|---|---|---|
| **M1** (R$ 2,000 / 14 days) | Server, GraphHopper, landing page, backend auth, repo handoff | In progress |
| **M2** (R$ 2,000 / 14 days) | Android APK, Pix Split (Efí), paywall, "sentido casa" optimizer, admin panel | Not started |

Full roadmap: [`docs/04-ROADMAP-M1.md`](./docs/04-ROADMAP-M1.md) and [`docs/04-ROADMAP-M2.md`](./docs/04-ROADMAP-M2.md).

## Architecture (one-liner)

Flutter app → Fastify API on DigitalOcean → GraphHopper (self-hosted) + PostgreSQL + Redis → Efí Bank Pix for subscriptions.

Detailed architecture, flows, and contracts in [`docs/02-ARCHITECTURE.md`](./docs/02-ARCHITECTURE.md).

## Tech Stack

| Layer | Tech |
|---|---|
| Mobile | Flutter + Riverpod 3 |
| Backend | Node.js 20 + Fastify v5 + TypeBox |
| ORM / DB | Prisma 7 + PostgreSQL 16 |
| Cache | Redis 7 |
| Routing engine | GraphHopper (self-hosted, motorcycle profile) |
| Payments | Efí Bank API Pix v2 (mTLS, Split) |
| Landing | Next.js on Vercel |
| Server OS | Ubuntu 24.04 on DigitalOcean 8GB |

Locked versions and rationale: [`docs/decisions/`](./docs/decisions/).

## Repository Structure

```
.
├── CLAUDE.md                # Operating manual for AI agents (READ FIRST)
├── CONTRIBUTING.md          # Git workflow, commit format, branching
├── README.md                # You are here
├── SECURITY.md              # Security policy
├── TODO.md                  # Active task list (owned by Claude Code)
├── apps/                    # Application code (created as we build)
│   ├── backend/             # Fastify API
│   ├── landing/             # Next.js landing page
│   └── mobile/              # Flutter app (M2)
├── infra/                   # docker-compose, server provisioning
├── docs/
│   ├── 01-PROJECT.md
│   ├── 02-ARCHITECTURE.md
│   ├── 03-CONVENTIONS.md
│   ├── 04-ROADMAP-M1.md
│   ├── 04-ROADMAP-M2.md
│   ├── 05-LGPD.md
│   ├── 06-DISASTER-RECOVERY.md
│   ├── decisions/           # ADRs (Architecture Decision Records)
│   └── sessions/            # AI session logs
└── scripts/                 # Repo-level utilities
```

## For AI Agents

If you are an AI agent (Claude Code, Cursor, Claude web), **start by reading [`CLAUDE.md`](./CLAUDE.md) in full**. It is the operating manual for this repository.

## For Humans

- Project owner: Eduardo Rodrigues — `eduardo@ianelli.tech`
- GitHub: [`ZenniTTy/-APP---Entrega-Smart`](https://github.com/ZenniTTy/-APP---Entrega-Smart) (transferring to client after handoff)
- Workana proposal: M1 + M2 = BRL 4,000 (escrow, milestone-based)

## License

Proprietary. All rights reserved by the project owner and the client.
