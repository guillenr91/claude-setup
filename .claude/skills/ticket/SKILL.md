---
name: ticket
description: >-
  Create, resume, and maintain ticket context in .claude/context/tickets/<TICKET_ID>/ using
  ANALYSIS.md and PLAN.md. Trigger when the user explicitly starts or resumes ticket work (for
  example /ticket, "start a new ticket", "continue <ID>", "work on <ID>") or asks to plan/do work
  for a ticket ID. Do not trigger for status-only, historical, or comparative mentions with no
  intent to work. If intent is ambiguous, ask for confirmation before taking action.
---

# Ticket Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents — preserve this standard in
every future edit.

Create, resume, and maintain ticket context under `.claude/context/tickets/<TICKET_ID>/`.

## Execution contract

1. Decide whether ticket work is actually happening.
2. Identify the ticket ID.
3. Pick exactly one mode:
   - **Mode A — New ticket**: no analysis file exists yet. Create it.
   - **Mode B — Resuming work**: analysis file exists. Load it for context before anything else.
   - **Mode C — Mid-work update**: a finding during work changes the analysis. Update the file.
4. Follow that mode's steps.

## Writing principle

Write ticket files for a newcomer with no knowledge of the ticket, project, codebase, terminology, or prior
conversation. Include enough verified context for that reader to understand:

- Business context and why the work matters.
- How the relevant system currently works (concepts, terminology, data flows).
- What is broken or missing, and why.
- Which data sources or code paths are involved.
- Which solution was chosen, including the opposing case and why it still wins.

Do not assume prior knowledge. Explain the normal behavior before explaining the change or bug.

## Boundary with general context

Ticket-specific facts → `.claude/context/tickets/<TICKET_ID>/`.
Durable, reusable info (setup, technical, troubleshooting) → `SETUP.md` / `TECHNICAL.md`, routed per
`.claude/context/CLAUDE.md`.

When ticket work reveals a reusable rule, extract it into the appropriate shared file. Keep ticket ID, temporary tags,
disposable resource names, validation logs, and command output in the ticket files.

Examples of durable findings that belong in project docs:

- A new external integration, schema, or store.
- A previously undocumented setup step, credential, or environment variable.
- An architecture detail, error pattern, or debugging technique future work will need.
- A verified command or troubleshooting fix not already documented.

If a finding is both ticket-relevant *and* durable, update **both**: ticket-specific framing in the ticket file, a
project-level entry in the appropriate doc.

If `SETUP.md` or `TECHNICAL.md` does not yet exist, follow the generation guidance in `.claude/context/CLAUDE.md`
rather than skipping the update or dumping the content into the ticket file. Verify before writing, per that file's
verification standards.

## Step 0 — Confirm intent on ambiguous triggers

If the trigger could be either ticket work or a status/historical/comparative reference, ask one short question:
"Are you starting/resuming work on `<TICKET_ID>` now, or just referring to it?" Do not load files, investigate, or
write anything until confirmed. If they say no, exit cleanly.

Skip this step on unambiguous triggers: explicit `/ticket`, "starting a new ticket", "continue with `<ID>`", etc.

## Step 1 — Establish the ticket ID

If the user provided one, use it. Otherwise, ask and stop until they answer. Do not invent or guess.

For the rest of the skill, refer to it as `<TICKET_ID>`. Each ticket has its own directory at
`.claude/context/tickets/<TICKET_ID>/` containing:

- `ANALYSIS.md` — problem, options, recommendation, decisions.
- `PLAN.md` — phases, current phase, branch, status.

## Step 2 — Pick the mode

- Directory does not exist → **Mode A**.
- Directory exists, user is starting work or asking for context → **Mode B**.
- Directory exists, new finding has emerged during work → **Mode C**.

## Mode A — Create the analysis file

Run all substeps before writing or editing application code.

### A.1 — Get the ticket content

Required: **Description** (what the ticket is about) and **Acceptance criteria** (what must be true when done).

If either is missing, ask and stop. Do not invent. Do not investigate or create files until both are available.

### A.2 — Investigate before writing

Ground claims in real files, functions, and current behavior. Cite `file_path:line_number` for any code referenced.

- **Bugs:** reproduce or directly observe the reported behavior when feasible. If you cannot reproduce, say so
  explicitly under "Reproduction / evidence".
- **Features / refactors:** document the existing behavior being changed.

#### A.2.1 — Investigation checklist

Before concluding you understand the problem space, cover these angles:

1. **Search by field or concept name, not only by table or class purpose.** Data often lives in tables whose primary
   purpose differs from your use case.
   ```bash
   rg -n "<fieldName>|<alternativeName>" -g "*.java"
   ```
2. **Trace both creation and deletion paths.** If data disappears on event A, also trace what happens when it was
   created — the creation path may write to stores that survive deletion.
3. **Check existing dependencies in the target file.** Before proposing new data sources, look at what the file
   already imports. The answer may be one existing injection away.
4. **Check what related endpoints already return.** If a similar endpoint exists (v4 when building v5), examine its
   data sources.
5. **Ask what persists and what is transient.** For data you assume is "deleted" or "cleared," verify there isn't a
   secondary copy, audit log, or history table that retains it.

### A.3 — Write the analysis file

Write `.claude/context/tickets/<TICKET_ID>/ANALYSIS.md` from this template, replacing placeholders. Write so a
newcomer with no project knowledge can understand the problem, current behavior, evidence, options, and
recommendation without reading prior conversation.

```markdown
---
ticket: <TICKET_ID>
created: <YYYY-MM-DD>
status: analysis
---

# <TICKET_ID>

## Context

This file is loaded into context. Keep it descriptive but concise, and understandable to a newcomer with no prior
project knowledge.

## Problem

<What is broken or missing, in the user's words plus your verified observations. Cite file_path:line_number for any code
referenced.>

## Acceptance criteria

<The conditions that define "done", as provided by the user. List verbatim or lightly edited for clarity. Do not invent.>

## Reproduction / evidence

<Bugs: reproduction steps or the observation that confirms the problem. If unverified, say so. Features / refactors:
the existing behavior being changed.>

## Root cause hypothesis

<Best current explanation. Mark as hypothesis until confirmed. Omit for pure feature work.>

## Data sources

<Relevant tables, APIs, caches, queues, files, or other data stores. For each: name, key fields, what it captures,
limitations.>

## Constraints

<Anything that narrows the solution space: API compatibility, performance budgets, deadlines, dependencies,
permissions, repository conventions.>

## Options

### Option A — <short name>

- Sketch: <what changes, where>
- Pros:
- Cons:
- Risk / blast radius:
- Effort: <S / M / L>

### Option B — <short name>

- Sketch:
- Pros:
- Cons:
- Risk / blast radius:
- Effort:

### Option C — <short name>  (add more or fewer as warranted; minimum two real options)

- Sketch:
- Pros:
- Cons:
- Risk / blast radius:
- Effort:

## Recommendation

<Which option to choose and why. State the strongest opposing case first, then explain why the recommendation still
wins.>

## Open questions

<Questions that must be answered before implementation. If none, write "none". When answered, remove the question and
fold the answer into the relevant section above.>
```

### A.4 — Wait for the user to choose

After writing, summarize the recommended option in 1–2 sentences and ask which option to use. **Do not start
implementation until the user explicitly chooses an option from the document.**

### A.5 — Create PLAN.md once an option is chosen

After the user chooses, create `.claude/context/tickets/<TICKET_ID>/PLAN.md` so a newcomer can see exactly where the
work stands.

PLAN.md must contain:

- **Branch** — git branch where work is happening. If it doesn't exist yet, propose a name and confirm before
  creating. Update if it changes.
- **Current phase** — the phase in progress. Keep accurate as work moves.
- **Status summary** — 1–2 sentences a newcomer can read to know what is happening right now (e.g. "Phase 2 in
  progress; data-access layer wired up, integration tests pending").
- **Phases** — ordered list of the smallest meaningfully testable changes. Each phase must produce an observable
  result (passing test, queryable row, working endpoint, successful build with new behavior). Do not create phases
  for empty scaffolding with no verifiable behavior — fold scaffolding into the first phase that proves it works.
  For each phase: name, goal, affected files / areas, verification, status (`pending` | `in progress` | `done`). If
  prerequisite bugs must be fixed before the main feature works, make them early phases.
- **Decisions log** — material decisions made during implementation that a future reader needs. Append; do not
  overwrite.

```markdown
---
ticket: <TICKET_ID>
created: <YYYY-MM-DD>
status: not-started  # one of: not-started, in-progress, blocked, done
---

# <TICKET_ID> — Implementation plan

## Branch

<branch name, e.g. feature/ABC-123-short-slug>

## Current phase

<phase name, or "not started">

## Status summary

<One or two sentences a newcomer can read to know exactly where things stand right now.>

## Phases

### Phase 1 — <short name>  [pending | in progress | done]

- Goal:
- Files / areas affected:
- Verification: <how this phase is tested before moving on>
- Notes:

### Phase 2 — <short name>  [pending | in progress | done]

- Goal:
- Files / areas affected:
- Verification:
- Notes:

(add more phases as needed; each must be a smallest meaningfully testable change)

## Decisions log

- <YYYY-MM-DD>: <decision and one-line reason>
```

Keep PLAN.md current. `Current phase`, `Status summary`, branch, and phase statuses must reflect reality.

## Mode B — Resume work from existing analysis

Use this when the user is continuing work on a ticket whose directory already exists.

1. Read **both** files in full before answering, suggesting changes, or making edits:
   - `ANALYSIS.md` for problem, options, decisions.
   - `PLAN.md` for current phase, branch, status.
2. Confirm the active git branch matches the branch in PLAN.md. If not, surface the discrepancy and ask before doing
   any work — do not silently switch or assume.
3. Use these files as the source of truth for problem, constraints, chosen option, current phase, and open questions.
   Do not re-derive what is already documented.
4. If the user's request conflicts with what's documented (different option, different phase ordering, etc.), surface
   the conflict and ask before proceeding. Do not silently override.
5. If PLAN.md is missing but ANALYSIS.md exists, the ticket predates the plan stage or PLAN.md was never created —
   offer to create it now using A.5.
6. If either file is wrong or incomplete, switch to Mode C.

## Mode C — Update the analysis file with new findings

During ticket work, update `ANALYSIS.md` only when a **material** finding emerges. A finding is material when it does
at least one of:

- Changes the **direction** of the work.
- Changes the **scope** of the work (adds, removes, or reshapes what's being delivered).
- Changes or invalidates a documented constraint.
- Rules out an option, or surfaces a new option.
- Changes the recommendation or the chosen option.
- Reveals a root cause that contradicts the prior hypothesis.
- Answers an item in "Open questions" or adds a new one.

Do **not** update ANALYSIS.md for routine progress, minor observations, or anything already implied. ANALYSIS.md is
a planning artifact, not a work log.

When you do update:

1. Edit the relevant section in place. Preserve existing structure.
2. If a documented decision, direction, or scope changes, briefly note what changed and why in "Recommendation" or
   "Open questions". Include enough context for a future reader to reconstruct the reasoning.
3. Re-read the changed section and confirm it still makes sense to a newcomer with no prior project knowledge.
4. Tell the user what you changed and why, in 1–2 sentences. Do not paste the full diff.

### Keeping PLAN.md current

Update PLAN.md whenever:

- A phase changes status (`pending` → `in progress` → `done`).
- The current phase or status summary changes.
- The branch changes.
- A material implementation decision is made — append to the decisions log with date and one-line reason.
- A direction or scope change in ANALYSIS.md invalidates the planned phases — revise the phases to match.

Each phase remains a smallest meaningfully testable change. If a phase grows during work, split it.

## Hard rules

- **Do not skip Mode A investigation.** An analysis built only from the ticket text is not useful.
- **Every option is a real option.** Do not pad with strawmen. If you genuinely see only one viable option, say so
  and explain why alternatives were rejected — do not invent fakes.
- **Mode B reads both files in full.** Do not skim or guess.
- **Mode C updates only for material findings.** Do not turn ANALYSIS.md into a work log.
- **Don't guess where a finding belongs.** If uncertain whether something is ticket-specific or durable, ask before
  writing.

## Ticket commit rules

These apply on top of the general commit conventions in the project root `CLAUDE.md` (which already covers the
`<TICKET_ID>: ...` subject-line prefix).

1. **Keep PLAN.md current at commit time.** If a commit completes any phases, mark each completed phase as `done`
   and refresh `Current phase` and `Status summary`. The PLAN.md update must land before or with the same commit.
