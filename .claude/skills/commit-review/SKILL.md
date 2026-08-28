---
name: commit-review
description: >-
  Commit conventions, pre-commit code review, and commit-message approval gate.
  Invoke before running `git commit` or `git push`, and when the user asks to
  draft a commit message. Do not invoke for read-only git operations
  (`git status`, `git log`, `git diff`), for GitHub write actions (`gh pr
  create`, `gh pr edit`, PR reviews or comments) — those are covered by
  manage-pull-request — or for reviewing someone else's PR.
---

# Commit Review Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Applies commit conventions, pre-commit review, and commit-message approval before `git commit` or `git push`.

## Commit conventions

Apply to every commit, ticket or not.

Never commit repository-local agent instruction files unless the repository exists specifically to maintain them.
In normal project repos, treat them as local config.

1. Self-contained and testable. Each commit must compile, pass its own verification, and make sense without a later
   commit. Prefer small commits. Keep tightly coupled edits together (rename + reference updates = one commit). Put
   unrelated fixes in separate commits. A class plus its tests = one change. Feature-flag plumbing + the gated feature
   = two changes when the plumbing is testable on its own.
2. Concise imperative subject. State what changed.
3. Bulleted body only when there are multiple changes. One present-participle bullet per change:
   ```
   - Adding AuthMiddleware to centralize token validation
   - Removing unused legacy session cookie helpers
   - Updating LoginController to call AuthMiddleware before dispatch
   ```
   Single-change commit → subject only, no one-bullet body restating the subject. If the reason is not obvious from the
   diff, add one short paragraph after the subject or bullets.
4. Ticket prefix when applicable. Format: `<TICKET_ID>: <description>` (e.g. `ABC-123: extract auth middleware`).
   A commit is a ticket commit if the ticket skill is active for a known `<TICKET_ID>` OR the branch encodes one
   (`feature/ABC-123-...`, `bugfix/PROJ-4567`, `ABC-123/...`). Otherwise omit the prefix.

For ticket-specific conventions beyond these, see the ticket skill when it exists.

## Pre-commit review

Triggers immediately before running `git commit` or `git push`.

Invoke the `code-review-effort` skill and apply its rules to the pending changes — every time, even when the change
feels small. Complete the review (including any fixes triaged from findings) before drafting the commit message.

## Commit-message approval gate

Never run `git commit` until the operator has seen the exact commit message and explicitly approved it.

1. Draft the full commit message (subject and body) in chat, formatted per `## Commit conventions`.
2. Show which files will be staged and which pending changes will be left out of this commit.
3. Include the review summary produced by `code-review-effort` (what was reviewed, findings, what was fixed, what
   was deferred) either in the commit body or alongside the draft.
4. Wait for explicit approval. "Looks good", "go ahead", "commit it", "ship it", or equivalent counts. Do not infer
   approval from silence, from earlier turns, or from prior approvals on different content.
5. Approval of one draft does not extend to later edits. After any change to the message or the staged file set,
   re-confirm.
6. If the operator rejects the draft or any part of it, drop the rejected piece. Do not commit anyway and do not
   re-draft a near-duplicate to argue the point.

Approval covers `git commit` only. `git push` is a separate step; do not push on the operator's behalf unless they
explicitly ask.
