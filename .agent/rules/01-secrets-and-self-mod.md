---
trigger: always_on
---

<!--
Activation: Always On (intended). Confirm in Antigravity UI.
Antigravity has NO equivalent of Claude Code's PreToolUse hook (block-env.sh).
This rule is the ONLY enforcement layer when working in Antigravity.
-->

# Secrets, Stack Changes, and Self-Modification

## FORBIDDEN TO EDIT

Antigravity has **no PreToolUse hook**. The `.claude/hooks/block-env.sh` that mechanically prevents Claude Code from editing these files does not run here. You — the Agent — are the only guard.

**Refuse to edit any of these files. If the user asks, explain that they must edit manually:**

- `.env`, `.env.*` (including `.env.deploy`) — except `.env.example`
- `*.jks`, `*.p12`, `*.pem`, `*.key`, `*.pfx` (Android signing material, certificates)
- `apps/mobile/android/key.properties`
- `apps/mobile/android/app/google-services.json`
- `apps/mobile/ios/Runner/GoogleService-Info.plist`
- Anything under `secrets/` or `certs/`

If a secret leaks, the user must rotate it immediately and scrub history with `git filter-repo`. Don't try to scrub history yourself unless explicitly instructed.

## Stack changes require an ADR

The locked stack lives in `CLAUDE.md` §"Stack — Locked Versions". Any change to `package.json`, `pubspec.yaml`, `apps/backend/prisma/schema.prisma`, `docker-compose*.yml`, or anything under `infra/` requires a new ADR in `docs/decisions/` in the SAME commit set.

If asked to add a dependency or bump a version without an ADR:

1. Refuse the unscoped edit.
2. Offer to draft the ADR first.
3. Only proceed once the ADR exists.

## Self-modification is forbidden

You may not edit `CLAUDE.md`, `AGENTS.md`, `.agent/rules/`, `.agent/workflows/`, `.agent/skills/`, `.claude/agents/`, `.claude/hooks/`, or `.claude/settings.json` without explicit human approval in the conversation. "Approval" means the user typed words like "yes, update CLAUDE.md" or "edit that rule" — never inferred from context.
