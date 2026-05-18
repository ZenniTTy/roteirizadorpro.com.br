---
name: session-end
description: Run the Session End Protocol from CLAUDE.md — update TODO.md, create docs/sessions/YYYY-MM-DD-NN-<topic>.md from the template, append the session to docs/sessions/0001-INDEX.md, and commit all three together with "docs(sessions): <topic>". Use at the end of any meaningful session (after merging work, finishing a feature, closing a discussion). Argument: a 2–4 word topic in kebab-case (e.g. "hooks-and-skills-setup"). Without an argument, infer the topic from conversation and confirm before proceeding.
disable-model-invocation: true
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git status:*), Bash(git diff:*), Bash(git log:*), Bash(git show:*), Bash(cp:*), Bash(ls:*), Bash(date:*)
---

# Session End Protocol

This skill enforces the ritual defined in [CLAUDE.md → Session End Protocol](../../../CLAUDE.md). Skipping any step leaves the project history incomplete.

## Step 1 — Determine the session ID

Run the helper script. It echoes `YYYY-MM-DD-NN` using America/Sao_Paulo time and the next available sequence for today.

```bash
"$CLAUDE_PROJECT_DIR"/.claude/skills/session-end/next-session-id.sh
```

If the user passed a topic in `args`, use it. Otherwise, propose a kebab-case topic synthesized from the conversation and **wait for confirmation**.

The full filename is `<session-id>-<topic>.md`, e.g. `2026-05-08-02-hooks-and-skills-setup.md`.

## Step 2 — Update TODO.md

Re-read [TODO.md](../../../TODO.md). For each task that was completed in this session:

- Move from `[ ]` to `[x]`.
- Keep the original wording — don't rephrase historical tasks.

For each new task discovered:

- Append `[ ] <task>` under the appropriate section. If no section fits, add to the bottom under the same heading style used elsewhere in the file.

## Step 3 — Author the session log

Copy the template:

```bash
cp "$CLAUDE_PROJECT_DIR"/docs/sessions/0000-template.md \
   "$CLAUDE_PROJECT_DIR"/docs/sessions/<session-id>-<topic>.md
```

Fill every section. **Do not leave placeholders.** Reference material (Section: "Reference Material Used") is mandatory if you queried Context7, fetched a URL, or read external docs — list each one.

The "Hand-off Notes for Next Session" section is the most-read part by the next agent. Be concrete: current branch, in-progress work, blockers, what to read first.

## Step 4 — Update the index

Open [docs/sessions/0001-INDEX.md](../../../docs/sessions/0001-INDEX.md). Insert one line **immediately after** the `## Sessions` heading, above the previous most-recent entry:

```
- [<session-id> — <topic>](./<session-id>-<topic>.md) — <one-line summary>
```

The summary mirrors the "Goal of the Session" section, condensed to one sentence.

## Step 5 — Commit all three together

```bash
cd "$CLAUDE_PROJECT_DIR"
git add TODO.md docs/sessions/<session-id>-<topic>.md docs/sessions/0001-INDEX.md
git status   # verify ONLY these three files are staged
git commit -m "docs(sessions): <topic>"
```

If `git status` shows other staged files, stop and ask the user — the protocol commit must be surgical (Karpathy: Surgical Changes).

## Verification before reporting done

Run all of these and confirm the output:

```bash
cd "$CLAUDE_PROJECT_DIR"
git log --oneline -1                               # last commit message starts with docs(sessions):
git show --stat HEAD                               # exactly 3 files in the commit
ls docs/sessions/ | grep "$(date -u +%Y-%m-%d)"    # new file is on disk
```

Only after all three confirm, tell the user the session is closed.

## Notes

- **Never `git push`** as part of this protocol unless the user explicitly asks. The commit stays local.
- **Never amend** an existing session commit — if you forgot something, create a follow-up commit.
- The session-end commit is the **only** commit allowed to touch all three files at once. Any other commit that bundles them is wrong.
