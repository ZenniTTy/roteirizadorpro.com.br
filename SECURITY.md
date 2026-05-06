# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in Roteirizador Pro, **do not open a public issue**.

Email: `security@roteirizadorpro.com.br` (placeholder until DPO email is finalized — temporary contact: `eduardo@ianelli.tech`).

Please include:
- A description of the vulnerability.
- Steps to reproduce.
- Potential impact.
- Suggested fix, if you have one.

We aim to respond within 72 hours.

## Supported Versions

While the project is in active development (M1, M2), only the latest commit on `main` is "supported" for security updates. Older tags or branches receive no security patches.

| Version | Status |
|---|---|
| `v1.0-m1` and later | Supported (latest only) |
| Anything older / unreleased | Not supported |

## Security Measures In Place

### Application

- HTTPS enforced (Let's Encrypt) on every endpoint.
- HSTS, X-Frame-Options, CSP headers via `@fastify/helmet`.
- Bcrypt with cost factor 12 for password hashing.
- JWT with RS256 signature, short access tokens (15 min) + refresh tokens (7 days).
- Refresh token rotation (a used refresh is invalidated, replaced with a new one).
- Rate limiting on `/auth/*` endpoints to mitigate credential stuffing.
- Helmet, CORS, and rate-limit on every Fastify route.
- Webhook signature validation (HMAC) for Efí Bank events.

### Infrastructure

- Server: SSH key-only authentication, root login disabled, password authentication disabled.
- `ufw` firewall blocking everything except 22, 80, 443.
- `fail2ban` against SSH brute-force.
- Unattended-upgrades for Ubuntu security patches.
- PostgreSQL and Redis bound to `127.0.0.1` only — never exposed externally.
- `.env` files stored on server with `chmod 600`, never in Git.
- Docker containers run as non-root where supported.

### Code

- Strict TypeScript (`strict: true`, `noUncheckedIndexedAccess: true`).
- Dart null safety enforced.
- Dependencies pinned in lockfiles (`package-lock.json`, `pubspec.lock`).
- Linter rules forbid `any` / `dynamic` without justification.

### Repository

- `.gitignore` blocks all common secret file patterns (`.env`, `*.pem`, `*.p12`, `certs/`, etc.).
- No secrets ever committed (per CLAUDE.md mandate).
- Force-push forbidden on `main` and `develop`.

## Incident Response

If a security incident occurs:

1. **Contain.** Take affected services offline if necessary.
2. **Rotate.** All potentially compromised credentials must be rotated immediately. See `docs/06-DISASTER-RECOVERY.md` Scenario 7.
3. **Investigate.** Determine scope, timeline, affected users.
4. **Notify.** If user data was accessed, notify ANPD (LGPD authority) and affected users in a reasonable timeframe (LGPD Art. 48).
5. **Document.** Write a session log with full timeline, root cause, and remediation. File under `docs/sessions/incidents/`.

## Privacy

For data handling and user rights under LGPD, see `docs/05-LGPD.md`.

## Bug Bounty

There is no formal bug bounty at this stage. Reasonable disclosure is welcomed and will be acknowledged in a security note.
