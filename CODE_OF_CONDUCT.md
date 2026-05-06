# Code of Conduct

## Scope

This document applies to anyone interacting with this repository — humans, AI agents, and the project's stakeholders (Eduardo, the client, the client's partner). It covers conduct in commit messages, code reviews, documentation, session logs, and any other repository surface.

## Expected Behavior

- Be direct and respectful. Brevity is fine; rudeness is not.
- Disagree on technical merits, not on people.
- When you make a mistake, own it briefly, fix it, and move on. No theatrics.
- Document decisions so future readers (including future-you) understand the why.
- Treat every secret as if it were live — even in conversations and tickets.

## AI Agent Conduct

AI agents (Claude Code, Cursor, Claude web, others) acting on this repo:

- Read `CLAUDE.md` before any action.
- Cite primary sources when stating facts that affect decisions (Anthropic docs, Karpathy primary, Context7).
- Surface uncertainty honestly. Wrong-confident is worse than asking.
- Never modify safety rules, security policies, or this Code of Conduct without explicit human approval.
- Log meaningful sessions in `docs/sessions/`.

## Unacceptable Behavior

- Committing secrets, credentials, or API keys, even temporarily.
- Force-pushing to `main` or `develop`.
- Bypassing the Context7 / Filesystem-read protocol because "it'll probably work."
- Copying any visual asset from Circuit (icons, illustrations, microcopy, palette) — see ADR-0010.
- Claiming work was tested when it was not.
- Inserting AI-generated co-author attributions or marketing in commit messages or PR descriptions.

## Reporting Issues

For technical issues, open a GitHub issue (after handoff) or message Eduardo directly.

For conduct issues involving the human stakeholders, email Eduardo at `eduardo@ianelli.tech`.

## Enforcement

Violations are addressed proportionally:

- First: clarification and request to amend.
- Second: explicit warning logged in a session entry.
- Third: removal of repository access (where applicable).

For AI agents, repeated violation of the protocol constitutes a tooling/prompt failure and triggers review of the relevant CLAUDE.md instruction.
