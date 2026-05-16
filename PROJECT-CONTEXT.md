# PROJECT-CONTEXT.md — Roteirizador Pro

> Paste this file at the start of any new AI session (Claude web, Claude Code, Cursor) to give the agent full project context instantly.
>
> **Repo path (Mac):** `/Users/eduardorodrigues/Downloads/Elo Vision Digital/[EVD] - Meus Projetos/[APP] - Entrega Smart`
> **GitHub:** `https://github.com/ZenniTTy/-APP---Entrega-Smart`
> **Last updated:** 2026-05-16

---

## What This Project Is

**Roteirizador Pro** is an Android-only route planning app for Brazilian delivery riders (motoboys). Functional fork of Spoke Route Planner (formerly Circuit) with 100% original visual identity. APK direct download from `roteirizadorpro.com.br` — no Google Play Store.

**Business model:** BRL 25.90/month via Pix. Split 50/50 between two partners via Efi Bank native Pix Split. No cancellation — subscription expires in 30 days, user renews by paying again.

**Contract:** BRL 4,000 via Workana escrow. M1 = R$2,000 (infra + landing + backend). M2 = R$2,000 (APK + payments + all features).

---

## People

| Role | Name | Contact |
|---|---|---|
| Developer | Eduardo Rodrigues | eduardo@ianelli.tech / GitHub: ZenniTTy |
| Client (partner 1) | (client) | via Workana |
| Client partner (50% split) | (partner) | via client |

---

## Tech Stack (locked — do not change without ADR)

| Layer | Tech | Version |
|---|---|---|
| Mobile | Flutter + Riverpod 3 + @riverpod codegen | stable / 3.x |
| Backend | Node.js 20 LTS + Fastify v5 + TypeBox | — |
| ORM | Prisma 7 + @prisma/adapter-pg | 7.x |
| Database | PostgreSQL 16 | — |
| Cache | Redis 7 | — |
| Routing | GraphHopper self-hosted (motorcycle profile) | latest |
| Payment | Efi Bank API Pix v2 (mTLS, no official SDK) | — |
| Landing | Next.js 14 + Tailwind on Vercel | — |
| Server | Ubuntu 24.04 DigitalOcean (1GB/$6 now, resize 8GB/$48 post-M1) | — |

---

## Repository Structure

```
[APP] - Entrega Smart/
├── CLAUDE.md              <- AI operating manual (READ FIRST)
├── agents.md              <- Agent-specific rules
├── CONTRIBUTING.md        <- Git workflow, Conventional Commits
├── README.md / SECURITY.md / CODE_OF_CONDUCT.md
├── TODO.md                <- Active tasks (Phase 1-4)
├── PROJECT-CONTEXT.md     <- This file
├── apps/
│   ├── backend/           <- Fastify API
│   ├── landing/           <- Next.js landing
│   ├── mobile/            <- Flutter app
│   └── admin/             <- Partner dashboard (M2)
├── infra/graphhopper/     <- Docker config + PBF scripts
├── scripts/               <- backup-postgres.sh, reimport-sudeste.sh
└── docs/
    ├── FEATURES.md        <- 15 features (F01-F15) with flows and rules
    ├── SCREENS.md         <- 12 screens mapped from Spoke reference
    ├── DESIGN-SYSTEM.md   <- Visual tokens (colors, typography, components)
    ├── DESIGN-PROMPT.md   <- Prototype prompt for Claude Artifacts / Stitch
    ├── INFRA-ACCESS.md    <- DO + Vercel access, provisioning, secrets
    ├── 01-PROJECT.md      <- Vision, scope, milestones, stakeholders
    ├── 02-ARCHITECTURE.md <- System diagram, flows, data model, API contracts
    ├── 03-CONVENTIONS.md  <- Naming, code style, directory layout
    ├── 04-ROADMAP-M1.md   <- M1 sprint plan, approval criteria, risks
    ├── 04-ROADMAP-M2.md   <- M2 sprint plan, deliverables, risks
    ├── 06-DISASTER-RECOVERY.md
    ├── decisions/         <- ADR-0001 through ADR-0010
    └── sessions/          <- AI session logs (read last 3 on start)
```

---

## Development Order

1. Phase 1 — Mobile frontend (Flutter) — no server needed
2. Phase 2 — Backend + GraphHopper — local Docker
3. Phase 3 — Landing page — Vercel
4. Phase 4 — Server deploy — waiting on client DO droplet

Active tasks: `TODO.md`

---

## M1 Scope (verbatim — gates escrow release)

1. DigitalOcean server (Ubuntu 24.04, firewall, client ownership)
2. GraphHopper Sudeste < 200ms
3. Landing at roteirizadorpro.com.br with HTTPS
4. Backend: registration + login JWT
5. Code in client GitHub + install manual + demo video

**Approval criteria:** site live + API responds + routes <200ms + client server panel access

**Notes:** Landing on Vercel. GraphHopper starts SP-only (1GB). Resize 8GB + full Sudeste post-M1.

---

## Critical Product Decisions

- Paywall: Iniciar Navegacao is the gate. Adding stops and optimizing are free.
- No cancellation: zero cancel buttons anywhere. Subscription expires 30 days. Renews by paying again. Prevents chargeback abuse.
- No refunds: Efi Bank Pix Split does not support refunds on split cobrancas.
- No Play Store (V1): APK at roteirizadorpro.com.br/download
- Clone positioning: replicate flows/UX only. No icons, colors, typography, illustrations, microcopy from Spoke/Circuit. (ADR-0010)
- Payment: Efi Bank only (not Mercado Pago, not Primepag). Pix Split 50/50 native.
- No AI features: OCR (MLKit) and STT are deterministic ML. Route is TSP algorithm. No LLMs.

---

## Visual Identity

- Primary: #6C3FC5 (deep purple)
- Background: #FFFFFF (white)
- Font: Poppins (Google Fonts)
- Style: modern, clean, minimalist, all corners rounded
- Icons: Lucide Icons (outlined, MIT)
- Full spec: docs/DESIGN-SYSTEM.md

---

## Infrastructure Access

| Service | Status | Level |
|---|---|---|
| DigitalOcean | Account active, droplet NOT created | Owner |
| Vercel | Account active, project created | Owner |
| GitHub | ZenniTTy/-APP---Entrega-Smart | Owner (transfers at M1) |
| Efi Bank | Both partner accounts ready | Client-owned |

Full guide: docs/INFRA-ACCESS.md

---

## Operating Rules for AI Agents

1. Read CLAUDE.md + agents.md before any action.
2. git status before any Git operation.
3. Read file before editing — never edit blindly.
4. Context7 mandatory before proposing or installing any library.
5. Conventional Commits via osascript on Mac.
6. No code comments in production code.
7. One TODO item at a time: complete, verify, commit, next.
8. Session end: update TODO.md + write session log + push.
9. Docs win over chat — single source of truth.

---

## Where to Find Details

| Question | File |
|---|---|
| Feature flows and rules | docs/FEATURES.md |
| Screen layouts | docs/SCREENS.md |
| Colors, fonts, components | docs/DESIGN-SYSTEM.md |
| Active tasks | TODO.md |
| Technology decisions | docs/decisions/ |
| System architecture | docs/02-ARCHITECTURE.md |
| M1 / M2 detail | docs/04-ROADMAP-M1.md / M2.md |
| DO and Vercel setup | docs/INFRA-ACCESS.md |
| Recent AI decisions | docs/sessions/0001-INDEX.md |
