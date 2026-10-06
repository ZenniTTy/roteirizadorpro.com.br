# Roteirizador Pro

Android route-planning app for delivery riders, distributed as APK from `roteirizadorpro.com.br`. Functional fork of [Spoke/Circuit Route Planner](https://getcircuit.com) with original visual identity, self-hosted infrastructure, and a planned 50/50 partner revenue split via Pix.

Detailed roadmap: [`docs/08-ROADMAP-v2.md`](./docs/08-ROADMAP-v2.md) (v1 archived 2026-05-26 to `docs/archive/` per [ADR-0035](./docs/decisions/0035-spoke-functional-clone-prototype-creative-reference.md)).

## Stack

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
├── TODO.md                 
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
│   ├── 08-ROADMAP-v2.md         
│   ├── 09-DISASTER-RECOVERY.md
│   ├── 10-CHANGELOG.md
│   ├── decisions/           # ADRs
│   ├── sessions/            # AI session logs
│   └── superpowers/         # Specs and plans
└── scripts/                 # Repo-level utilities
```

## For AI Agents

If you are an AI agent (Claude Code, Cursor, Claude web), **start by reading [`CLAUDE.md`](./CLAUDE.md) in full**. It is the operating manual for this repository.

## License

Proprietary. All rights reserved by the project owner and the client.
