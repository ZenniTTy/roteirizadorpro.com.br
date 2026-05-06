# Pull Request

## What changed

Brief summary of the change. Reference any related issue/ADR/TODO entry.

- Closes: #
- Related ADR:
- Related TODO item:

## Why

Why is this change needed? What problem does it solve? Optional — skip if obvious from "What changed".

## How to test

Concrete reproduction steps. Anyone reviewing should be able to follow these and verify.

```
# example
cd apps/backend
npm test -- auth
```

For UI changes, attach a screenshot or screen recording.

## Verification done

- [ ] Linter clean
- [ ] Tests added or updated where it hurts (per CLAUDE.md "tests where it hurts" guidance)
- [ ] Manual verification against the feature spec
- [ ] Docs updated (`docs/`, ADR, TODO.md if needed)
- [ ] No secrets committed
- [ ] Branch is up to date with `develop`

## Risk

What could break? What's the blast radius if this is wrong?

- Risk: <low | medium | high>
- Affected systems: <list>
- Rollback plan: <how to revert>

## Notes for reviewer

Anything specific the reviewer should look at? Edge cases, design tradeoffs, things you're unsure about?
