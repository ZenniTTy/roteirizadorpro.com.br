---
description: Close a session by updating TODO.md, creating a session log, and committing the three together. Optional post-reset — only when work is non-obvious from git log.
---

# /session-end

Per CLAUDE.md (post 2026-05-26 reset): **sessions are optional**. Only run this workflow when the session's work is non-obvious from `git log` — meaning at least one of:

- A non-trivial architectural decision was made.
- Technical debt was knowingly accepted (and is worth flagging for future sessions).
- A lesson was learned that other sessions might repeat without this note.

If none of these apply, **skip this workflow** — well-written commits already cover what happened.

## Steps

1. Ask the operator one question if not clear from context: *"Is there a non-obvious decision, accepted debt, or repeatable lesson from this session that belongs in a session log? If not, we should skip /session-end."* Wait for the answer. If "skip", stop here.

2. Read the template:
   ```
   docs/sessions/0000-template.md
   ```

3. Read the last 3 entries in `docs/sessions/0001-INDEX.md` to copy the topic-line style.

4. Update `TODO.md`:
   - Mark completed items `[x]`.
   - Add discovered items `[ ]` with a short note.

5. Create the new session log at:
   ```
   docs/sessions/YYYY-MM-DD-NN-<topic>.md
   ```
   Where `YYYY-MM-DD` is today's date, `NN` is the next two-digit sequence in `docs/sessions/` for that date, and `<topic>` is kebab-case.

6. Append a new line to `docs/sessions/0001-INDEX.md` matching the existing style.

7. Commit all three files (`TODO.md`, the new session, and the updated INDEX) together:
   ```
   docs(sessions): <session topic, ≤ 72 chars>
   ```

## Report

Print:
- Path of the new session file.
- The commit SHA.
- One-sentence summary of what the log captured.

## Anti-patterns

- Don't create a session for routine slice work that's plainly in the diff.
- Don't dump the entire conversation transcript into the session — extract the decision/lesson.
- Don't commit `TODO.md` or the session file separately from the INDEX update.
