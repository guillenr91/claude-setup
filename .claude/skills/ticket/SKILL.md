---
name: ticket
description: >-
  Manage the ticket directory at .claude/context/tickets/<TICKET_ID>/ (analysis file plus PLAN.md)
  across the lifecycle of a ticket — create on a new ticket, read on resumed work, update as
  findings or phases change. TRIGGER when the user explicitly invokes /ticket, OR signals
  starting a new ticket ("I have to work on a new ticket", "I was assigned a new ticket",
  "we need to work on a ticket", "there is a ticket I need to work on", "starting a new ticket",
  "picking up ticket <ID>", "new ticket assigned", "got a new ticket", "let's start a ticket",
  "kicking off ticket <ID>"), OR signals resuming work on a ticket ("continue with ticket <ID>",
  "back to <ID>", "let's keep working on <ID>", "resuming <ID>", "going back to ticket <ID>",
  "next phase of <ID>", "more work on <ID>"), OR mentions a ticket-shaped ID (e.g. "ABC-123",
  "PROJ-4567", "JIRA-42") in the context of doing, planning, or discussing work on it. Do NOT
  trigger when the user asks a general code question that is not tied to ticket work; the ticket
  is mentioned only as historical context ("ABC-123 was the one we punted last sprint"); the
  user is asking a status or metadata question without intending to do work ("what's the state
  of ABC-123?", "who owns PROJ-4567?"); the user is comparing or referencing tickets without
  working on them ("similar to ABC-123", "like we did in PROJ-99"); the user explicitly says
  they are not working on the ticket right now ("not yet", "later", "just curious"); or the
  message is a one-line acknowledgement, thanks, or a non-actionable comment. When the message
  is genuinely ambiguous between a positive and negative trigger, load the skill and ask the
  user to confirm intent before taking any action — do not silently pick a side.
---

# Ticket Skill

Use this skill to create, resume, and maintain ticket context under `.claude/context/tickets/<TICKET_ID>/`.

## Execution contract

First decide whether ticket work is actually happening. If it is, identify the ticket ID, choose exactly one mode, then
follow that mode's steps.

- **Mode A — New ticket**: no analysis file exists yet. Create it.
- **Mode B — Resuming work**: an analysis file exists. Load it for context before doing anything else.
- **Mode C — Mid-work update**: a finding during work changes the analysis. Update the file.

## Writing principle

Write ticket files for a newcomer. The reader may know nothing about the ticket, project, codebase, terminology, or
prior conversation. Include enough verified context for that reader to understand:

- The business context and why the work matters.
- How the relevant system currently works, including concepts, terminology, and data flows.
- What is broken or missing, and why.
- Which data sources or code paths are involved.
- Which solution was chosen, including the opposing case and the reason it still wins.

Do not assume prior knowledge. Explain the normal behavior before explaining the change or bug.

## Boundary with general context

Ticket-specific facts belong in `.claude/context/tickets/<TICKET_ID>/`, not in shared project context. Keep
`SETUP.md`, `TECHNICAL.md`, and any project-specific files they route to ticket-neutral because they are loaded for
unrelated work.

When ticket work reveals a reusable setup step, technical behavior, or troubleshooting pattern, extract the general rule
into the appropriate shared context file. Keep the ticket ID, temporary image tags, disposable resource names,
validation logs, and command output in the ticket files.

## Step 0 — Confirm intent on ambiguous triggers

If the skill loaded because the user mentioned a ticket ID or phrasing that could be either ticket work or a
status/historical/comparative reference, ask the user to confirm before doing anything else. A single short question is
enough: "Are you starting/resuming work on `<TICKET_ID>` now, or just referring to it?" Do not load files, investigate
the codebase, or write anything until the user confirms they are doing work. If they say no, exit cleanly without side
effects.

Skip this step when intent is unambiguous — explicit `/ticket` invocation, "starting a new ticket", "continue with
`<ID>`", and similar clear signals do not need confirmation.

## Step 1 — Establish the ticket ID

If the user provided a ticket ID in their message or as an argument, use it. Otherwise, ask the user for the ticket ID
and stop until they provide one. Do not invent or guess an ID.

Once you have the ID, refer to it as `<TICKET_ID>` for the rest of this skill. Each ticket has its own directory at
`.claude/context/tickets/<TICKET_ID>/`, containing two files:

- `ANALYSIS.md` — the analysis document (problem, options, recommendation, decisions).
- `PLAN.md` — the implementation plan (phases, current phase, branch, status).

## Step 2 — Pick the mode

Check whether the directory `.claude/context/tickets/<TICKET_ID>/` exists and what is in it.

- **Directory does not exist** → Mode A.
- **Directory exists and the user is starting work or asking for context** → Mode B.
- **Directory exists and a new finding has emerged during work** → Mode C.

## Mode A — Create the analysis file

Run these substeps before writing or editing application code.

### A.1 — Get the ticket content

The analysis file requires both:

- **Description**: what the ticket is about.
- **Acceptance criteria**: what must be true when the ticket is done.

If either item is missing, ask for the missing item and stop. Do not invent ticket content. Do not investigate or create
files until both are available.

### A.2 — Investigate before writing

Investigate the codebase before writing the analysis. Ground claims in real files, functions, and current behavior.
Cite `file_path:line_number` for any code referenced.

For bug tickets, reproduce or directly observe the reported behavior when feasible. If you cannot reproduce it, write
that explicitly under "Reproduction / evidence". For feature or refactor tickets, document the existing behavior being
changed.

#### A.2.1 — Investigation checklist

Before concluding that you understand the problem space, verify you have covered these angles:

1. **Search by field or concept name, not only by table or class purpose.** If you need data X, search the entire
   codebase for field names that could hold X. Data often lives in tables whose primary purpose differs from your use
   case.
   ```bash
   rg -n "<fieldName>|<alternativeName>" -g "*.java"
   ```

2. **Trace both creation and deletion paths.** If data disappears on event A, also trace what happens when that data was
   created. The creation path may write to stores that survive the deletion.

3. **Check existing dependencies in the target file.** Before proposing new data sources, look at what the file you plan
   to modify already imports. The answer may be one existing injection away.

4. **Check what related endpoints already return.** If a similar endpoint exists (e.g., v4 when building v5), examine
   what data sources it uses and whether they contain what you need.

5. **Ask what persists and what is transient.** For any data you assume is "deleted" or "cleared," verify there isn't a
   secondary copy, audit log, or history table that retains it.

### A.3 — Write the analysis file

Write `.claude/context/tickets/<TICKET_ID>/ANALYSIS.md` from the template below. Replace placeholders with real values.

```markdown
---
ticket: <TICKET_ID>
created: <YYYY-MM-DD>
status: analysis
---

# <TICKET_ID>

## Problem

<What is broken or missing, in the user's words plus your verified observations. Cite file_path:line_number for any code
referenced.>

## Acceptance criteria

<The conditions that define "done" for this ticket, as provided by the user. List them verbatim or lightly edited for
clarity. Do not invent criteria.>

## Reproduction / evidence

<For bugs: reproduction steps or the observation that confirms the problem. If unverified, say so. For features or
refactors: the existing behavior being changed.>

## Root cause hypothesis

<Best current explanation. Mark it as a hypothesis until confirmed. Omit for pure feature work.>

## Data sources

<Relevant tables, APIs, caches, queues, files, or other data stores. For each source, document the name, key fields,
what it captures, and limitations.>

## Constraints

<Anything that narrows the solution space: API compatibility, performance budgets, deadlines, dependencies, permissions,
or repository conventions.>

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

<Which option should be chosen and why. First state the strongest opposing case, then explain why the recommendation
still wins.>

## Open questions

<Questions that must be answered before implementation. If none, write "none". When answered, remove the question and
incorporate the answer into the relevant section above.>
```

### A.4 — Wait for the user to choose

After writing the file, summarize the recommended option in one or two sentences and ask the user which option to use.

**Do not start implementation until the user explicitly chooses an option from the document.**

### A.5 — Create PLAN.md once an option is chosen

After the user chooses an option, create `.claude/context/tickets/<TICKET_ID>/PLAN.md`. Write it so a newcomer can
understand exactly where the work stands.

PLAN.md must contain at minimum:

- **Branch** — the git branch where the work is happening. If the branch does not yet exist, propose a name and
  confirm with the user before creating it. Update this field if the branch changes.
- **Current phase** — the phase in progress. Keep this field accurate as work moves forward.
- **Status summary** — one or two sentences a newcomer can read to know what is happening right now (e.g. "Phase 2 in
  progress; data-access layer wired up, integration tests pending").
- **Phases** — an ordered list of the smallest meaningfully testable changes. Each phase must produce an observable
  result, such as a passing test, queryable database row, working endpoint, or successful build with new behavior. Do
  not create phases for empty scaffolding with no verifiable behavior; fold scaffolding into the first phase that proves
  it works. For each phase, include name, goal, affected files or areas, verification, and status (`pending`,
  `in progress`, or `done`). If prerequisite bugs must be fixed before the main feature works, make them early phases.
- **Decisions log** — material decisions made during implementation that a future reader needs to reconstruct context.
  Append; do not overwrite.

Use this template:

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

Use this mode when the user is continuing work on a ticket whose directory already exists.

1. Read **both** files in full before answering, suggesting changes, or making edits:
    - `.claude/context/tickets/<TICKET_ID>/ANALYSIS.md` for problem, options, and decisions.
    - `.claude/context/tickets/<TICKET_ID>/PLAN.md` for current phase, branch, and status.
2. Confirm the active git branch matches the branch named in PLAN.md. If it does not, surface the discrepancy and ask
   before doing any work — do not silently switch or assume.
3. Use these files as the source of truth for the problem, constraints, chosen option, current phase, and open
   questions. Do not re-derive what is already documented.
4. If the user's current request conflicts with what is documented (different option, different phase ordering, etc.),
   surface the conflict and ask before proceeding. Do not silently override.
5. If PLAN.md is missing but the analysis file exists, the ticket was created before the plan stage existed or the plan
   was never created — offer to create PLAN.md now using A.5.
6. If either file is wrong or incomplete, switch to Mode C.

## Mode C — Update the analysis file with new findings

During ticket work, update `.claude/context/tickets/<TICKET_ID>/ANALYSIS.md` only when a **material** finding emerges.
A finding is material when it does at least one of these:

- Changes the **direction** of the work (different approach than what was chosen).
- Changes the **scope** of the work (adds, removes, or reshapes what is being delivered).
- Changes or invalidates a documented constraint.
- Rules out an option, or surfaces a new option.
- Changes the recommendation or the chosen option.
- Reveals a root cause that contradicts the prior hypothesis.
- Answers an item in "Open questions" or adds a new one.

Do **not** update ANALYSIS.md for routine progress, minor observations, or anything already implied by existing content.
ANALYSIS.md is a planning artifact, not a work log.

When you do update:

1. Edit the relevant section in place. Preserve the existing structure.
2. If a documented decision, direction, or scope changes, briefly note what changed and why in the "Recommendation" or
   "Open questions" section. Include enough context for a future reader to reconstruct the reasoning.
3. Tell the user what you changed in the file and why, in one or two sentences. Do not paste the full diff.

### Keeping PLAN.md current

PLAN.md must reflect reality. Update it whenever:

- A phase changes status (`pending` → `in progress` → `done`).
- The current phase or status summary changes.
- The branch changes.
- A material implementation decision is made — append to the decisions log with the date and one-line reason.
- A direction or scope change in the analysis file invalidates the planned phases; revise the phases to match.

Each phase remains a smallest meaningfully testable change. If a phase grows during work, split it.

### Scope boundary — what belongs in the ticket file vs. project docs

The ticket files are only for ticket-specific analysis and plan state: problem, options, chosen direction, trade-offs,
ticket-specific findings, phases, status, and decisions.

Durable technical information discovered during ticket work belongs in project docs, not only in ticket files.
Examples:

- A new external integration, schema, or store.
- A previously undocumented setup step, credential, or environment variable.
- An architecture detail, error pattern, or debugging technique future work will need.
- A verified command or troubleshooting fix not already documented.

To decide whether durable information goes in `SETUP.md` or `TECHNICAL.md`, follow the routing rules in
`.claude/context/CLAUDE.md`. If a finding is genuinely both ticket-relevant *and* durable (e.g. it shapes this ticket's
solution and future work needs it), update **both** places: ticket-specific framing in the ticket file, and a
project-level entry in the appropriate project doc.

If `SETUP.md` or `TECHNICAL.md` does not yet exist, follow the generation guidance in `.claude/context/CLAUDE.md` rather
than skipping the update or dumping the content into the ticket file. Verify before writing, per that file's
verification standards.

If you are uncertain where a finding belongs, ask before writing. Do not guess silently.

## Rules

- Do not skip the investigation step in Mode A. An analysis built only from the ticket text is not useful.
- Every option must be a real option. Do not pad with strawmen.
- If you genuinely see only one viable option, say so and explain why alternatives were rejected — do not invent fake
  alternatives.
- In Mode B, read both files in full before answering. Do not skim or guess.
- In Mode C, update only for material findings. Do not turn ANALYSIS.md into a work log.
- Keep PLAN.md current: `Current phase`, `Status summary`, branch, and phase statuses must reflect reality.
- Keep ticket-specific analysis in the ticket file. Keep durable technical and setup information in the project docs (
  `SETUP.md` / `TECHNICAL.md`), routed per `.claude/context/CLAUDE.md`.
- General commit conventions live in the project root `CLAUDE.md` and still apply.

## Ticket commit rules

These apply on top of the general commit conventions in the project root `CLAUDE.md` (which already covers the
`<TICKET_ID>: ...` subject-line prefix).

1. **Keep PLAN.md current at commit time.** If a commit completes any phases, mark each completed phase as `done` and
   refresh `Current phase` and `Status summary`. The PLAN.md update must land before or with the same commit.
