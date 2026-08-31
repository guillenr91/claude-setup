---
name: sync-ticket-context
description: >-
  Refresh the active ticket's context files (ANALYSIS.md, PLAN.md) and the
  project-level reference (SETUP.md, TECHNICAL.md) with information
  discovered since they were last written. Invoke when the user runs
  `/sync-ticket-context`, or explicitly asks to update ticket state,
  refresh the plan, capture findings, or write down what was learned. Do
  not invoke automatically at the end of every turn; the operator triggers
  this.
---

# Sync Ticket Context Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

On-demand refresh of both ticket-scoped files and project-level reference files based on what was learned this
session. Writes ticket-scope facts to `.claude/context/tickets/<TICKET_ID>/` (or `.agents/context/tickets/<TICKET_ID>/`
for non-Claude agents), and durable project-scope facts to `SETUP.md` / `TECHNICAL.md`.

## Boundary with the `ticket` skill

The `ticket` skill owns the create/resume/mid-work workflow (Modes A, B, C) and defines the file templates. This
skill runs on top of that: it collects every material change since the ticket files were last written and updates
them in one focused pass. If no ticket directory exists yet, defer to the `ticket` skill instead of creating one
here.

Never invent findings to fill a section. If nothing changed for a section, leave it alone.

## Step 0 — Establish the active ticket

1. Use the ticket ID the user names. If none is named, infer from the current git branch when it encodes one
   (`feature/ABC-123-...`, `bugfix/PROJ-4567`, `ABC-123/...`) OR the most recently-updated directory under
   `.claude/context/tickets/` (or `.agents/context/tickets/`).
2. If two candidates are plausible, ask which ticket. Do not guess.
3. If no ticket directory exists, stop and hand off to the `ticket` skill.

Refer to the resolved ID as `<TICKET_ID>` for the rest of the run.

## Step 1 — Collect what changed

Gather every material finding, decision, or state change since the ticket files were last written. Sources to
check, in order:

1. Commits since the ticket files last changed. Use the last commit that touched the ticket directory as the
   boundary:
   ```bash
   BASE=$(git log -1 --format=%H -- .claude/context/tickets/<TICKET_ID>/)
   git log --oneline "$BASE..HEAD"
   ```
   Substitute `.agents/context/tickets/` for non-Claude agents. Include commits on any ticket branch as well.
2. `gh pr view <n>` reviews, review comments, and CI outcomes when a PR exists.
3. The current conversation: any user-approved decision, tool output that verified a claim, live-run result,
   diagnostic finding, or rejected approach.
4. `git status` and `git diff` for uncommitted work that changes the picture.
5. Any file the ticket references (test suite, script, module) whose behavior was verified this session.

Only include facts you can cite in-session. If a claim would need re-verification, mark it and either re-verify
now or leave the claim out.

## Step 2 — Classify each finding

For every finding collected, decide where it belongs:

- Ticket-scope: current status, phase progression, decision reversals, reproduction evidence, per-case
  results, review-round history, merge details. Goes to `ANALYSIS.md` or `PLAN.md`.
- Project-scope (durable): behavior of a shared keyword/module/endpoint, a data-store quirk, a
  build/test/environment gotcha, a debugging technique, a resolution-order rule, or any pattern future tickets
  can reuse. Goes to `TECHNICAL.md` (or `SETUP.md` when the finding is a setup/credential/env step). See the
  Verification standards in `.claude/context/CLAUDE.md` (or `.agents/context/AGENTS.md`).
- Both: ticket framing plus a durable rule. Write to both, cross-link.
- Neither: routine progress, in-progress state, chat context, tool preferences. Do not persist.

If unsure whether a finding is durable, ask the operator rather than writing to project files on a guess.

## Step 3 — Update ticket files

### `ANALYSIS.md`

- Frontmatter: keep `ticket` and `created` unchanged. Update `status` — one of `analysis`, `in-progress`,
  `blocked`, `done`. When a PR exists, add these fields (not present in the base ANALYSIS.md template): `pr:`
  (PR number), and once merged, `merged_at:` (ISO date) and `merge_commit:` (SHA).
- Sections: edit `Problem`, `Reproduction / evidence`, `Root cause hypothesis`, `Data sources`, `Constraints`,
  `Options`, `Recommendation`, or `Open questions` in place when a material finding changes their content.
  Preserve structure. Do not turn `ANALYSIS.md` into a work log.
- Direction / scope changes: note the change and one-line reason inline in `Recommendation` or `Open
  questions`. ANALYSIS.md has no separate Decisions block; PLAN.md's Decisions log below covers material
  implementation decisions.

### `PLAN.md`

- Frontmatter: update `status` — one of `not-started`, `in-progress`, `blocked`, `done`. When a PR exists,
  add these fields (not present in the base PLAN.md template): `pr:` (PR number), and once merged,
  `merged_at:` (ISO date) and `merge_commit:` (SHA).
- `Branch`: correct if the working branch changed.
- `Current phase`: reflect the phase actually in progress. On merge, set to `Merged.` and cite the merge commit
  and date.
- `Status summary`: rewrite in 1–2 sentences so a newcomer can read it cold and know exactly where the work
  stands.
- `Phases`: update each phase's status (`pending` | `in progress` | `done`). If a phase grew during
  implementation, split it. If a new phase emerged (a review round that materially reshaped the work), append
  it.
- `Decisions log`: append dated entries for material decisions: review-round outcomes, root-cause
  corrections, scope changes, environment discoveries, merge confirmation. Keep prior entries as-is even when
  later evidence supersedes them; add a corrective entry rather than editing history.

## Step 4 — Extract durable findings to project files

For every finding classified as project-scope:

1. Grep the target project file for existing coverage. If a section already covers the topic, edit in place
   rather than duplicating.
2. Follow the structure required by `.claude/context/CLAUDE.md` (or `.agents/context/AGENTS.md`) — YAML front
   matter, standard opening line, TOC. If a new subsection appears in a file with a table of contents, add the
   corresponding TOC entry in the same edit.
3. Every claim must cite a verified source (file path with line number, command output run this session, live
   run result, external doc URL fetched this session). Mark unverifiable claims per the file's Verification
   standards or leave them out.
4. Update `last-verified` to today's date, and the file's verification paragraph, only for sections you
   actually re-confirmed this session.
5. Cross-link ticket ↔ project: the ticket file mentions the durable finding was extracted; the project file
   cites the ticket ID and date it was verified.

## Step 5 — Report

After all writes:

1. List every file changed and, for each, one line stating what was added or corrected. Skip a file if nothing
   changed.
2. Flag any finding you deliberately did not persist (e.g., "kept the DAX-staleness debate out of TECHNICAL.md
   because it was ticket-specific reasoning").
3. Do not paste full diffs unless the operator asks.

## Hard rules

- Never write a finding you did not verify this session as if it were fact. Apply the evidence-first skill's
  rules to every persisted claim.
- Never overwrite a decisions-log entry to make it look right in hindsight. Append a corrective entry.
- Never edit the project-agnostic style/convention files under `.claude/styles/` (or `.agents/styles/`) from
  this skill. Those have their own guide in `.claude/styles/CLAUDE.md` (or `.agents/styles/AGENTS.md`).
- Never persist ticket ID, temporary tags, or disposable resource names into `SETUP.md` / `TECHNICAL.md`. Those
  belong in the ticket files.
- Never commit or push as part of this skill. The commit-review skill governs commits; this skill only writes
  files.
