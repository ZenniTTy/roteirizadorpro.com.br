# ADR-0011: Use Bun as Package Manager (Node 20 LTS Stays the Runtime)

- **Status:** Accepted
- **Date:** 2026-05-08
- **Deciders:** Eduardo
- **Related ADRs:** ADR-0003 (Node 20 LTS + Fastify v5)

## Context

During Phase 1 setup we used npm for installs. `npm install` in `apps/backend/` took ~2 minutes and `apps/landing/` took ~1 minute on a fast connection. The user has Bun 1.3.13 installed locally and the `/saas-project-scaffold` skill (rejected wholesale earlier in this session) defaults to Bun for installs. The question came up: swap npm for Bun?

Bun can serve in two roles — package manager (replaces `npm install`, produces `node_modules` consumable by Node) and runtime (replaces `node` for executing JavaScript). These are independent decisions.

ADR-0003 locks **Node.js 20 LTS** as the runtime, primarily because (a) Fastify v5's plugin ecosystem is overwhelmingly Node-tested, (b) the production droplet plan in `docs/07-INFRA.md` provisions Node, and (c) bcrypt + pg + Prisma 7 driver adapter all have known-good Node 20 behavior. Replacing Node with Bun in the runtime would invalidate that ADR and require re-validating each native binding (bcrypt, pg, Prisma's `query_engine` binary loading).

We are 18 days from the M1 deadline. Risk budget for tooling changes is tight.

## Options Considered

### Option A — Keep npm everywhere

- Pros: Zero change. Already proven working through Phase 1. Industry default with the longest production track record. CI/CD examples are universal.
- Cons: Slow installs. A `nvm use && rm -rf node_modules && npm install` cycle takes ~3 minutes.

### Option B — Bun for install, Node for runtime (this ADR)

- Pros: ~10× faster installs (7s vs 2 min observed). Bun's package manager has been stable since 1.0; it consumes the same `package.json` and produces a compatible `node_modules`. `bun.lock` is text-format JSON (good for diffs) since Bun 1.1. Postinstall scripts of unknown packages are blocked by default — modest security improvement over npm.
- Cons: Two-tool split (Bun installs, Node runs) creates a mild conceptual overhead. CI/CD must install Bun. The dev machine and the production droplet must both have Bun installed. Some scripts that rely on npm-specific behavior (rare) need adjustment.

### Option C — Bun for install + runtime

- Pros: Single tool. Faster cold starts. Single-binary deploy.
- Cons: Replaces Node 20 LTS — invalidates ADR-0003. Native bindings (bcrypt, pg, Prisma) need re-validation. Fastify v5 has known compatibility with Bun, but the long-tail of plugins (helmet, jwt, rate-limit) is less tested. Production stability risk in the M1 window is unjustified for the marginal gain over Option B.

### Option D — Switch to pnpm

- Pros: Strong monorepo story. Fastest non-Bun install. Wider production track record than Bun.
- Cons: Ours is a small monorepo (3 apps), pnpm's hoisting model adds complexity we don't need at this scale, and we'd still pay the migration cost. No clear win over Bun-install for our shape.

## Decision

**Use Bun as the package manager for `apps/backend/` and `apps/landing/`. Keep Node 20 LTS as the JavaScript runtime.**

Concretely:

- `bun install` replaces `npm install`.
- `bun.lock` is the lockfile of record. `package-lock.json` is removed.
- `bunx <cmd>` replaces `npx <cmd>` for one-off CLI invocations (e.g., `bunx prisma generate`).
- `bun run <script>` invokes the script declared in `package.json`. Scripts themselves still call `node`, `tsc`, `tsx`, `prisma`, `next` — none of those switch to Bun's runtime.
- Production `Dockerfile` (Phase 3 work) installs both Bun (for the build stage) and Node 20 (for the run stage), or installs just Node and copies pre-built artifacts. Final decision deferred to Phase 3.

## Consequences

- Positive: Install time ~10× faster locally and in CI; bun.lock diffs are readable; postinstall scripts of unknown packages blocked by default.
- Negative: Dev machines and CI runners must install Bun. The production droplet provisioning script (`docs/07-INFRA.md`) gains a Bun install step. Two-tool mental model.
- Neutral: ADR-0003 (Node 20 LTS) unchanged — runtime did not move.

## Implementation Notes

- Local install: `curl -fsSL https://bun.sh/install | bash`.
- Bun version pinned via `bun --version` ≥ 1.3 in `package.json`'s `packageManager` field is **not** added in this ADR — Bun does not yet honor `packageManager`. Use `.tool-versions` (asdf) or `mise` if version pinning is needed later.
- CI/CD: GitHub Actions step `oven-sh/setup-bun@v2` installs Bun. Node 20 still installed via `actions/setup-node@v4` because tests, build, and runtime all run on Node.
- Lockfile policy: `bun.lock` committed; `package-lock.json` not generated and not tracked. If a contributor accidentally runs `npm install` and creates a `package-lock.json`, the commit hook (Phase 2 future work) should reject it.
- Postinstall trust list: `unrs-resolver` (transitive of `eslint-config-next`) was blocked on Phase 1 install. `bun run lint` works without trusting it, so we leave it untrusted. Re-evaluate per-package if a future blocked script breaks something user-visible.
- The bumped major deps that landed alongside this migration (`@fastify/jwt` 10, `@fastify/type-provider-typebox` 6, `bcrypt` 6, `pino` 10, `pino-pretty` 13, `dotenv` 17) are consequences of the Phase 1 audit, not of the package manager change. They are recorded in the commit message of `chore(backend): migrate to bun and bump compatible major deps`.

## References

- Bun docs: https://bun.sh/docs/cli/install
- Phase 1 version audit recorded in `docs/sessions/2026-05-08-01-phase-1-foundations.md` (extended on the same day; see commit history).
- ADR-0003 (Node 20 LTS + Fastify v5).
