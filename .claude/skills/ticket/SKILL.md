---
name: ticket
description: >-
  Manage the ticket directory at .claude/docs/tickets/<TICKET_ID>/ (analysis file plus PLAN.md)
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

# Ticket lifecycle

You are working on a ticket. This skill covers three modes — pick the one that matches the situation, then follow its
steps.

- **Mode A — New ticket**: no analysis file exists yet. Create it.
- **Mode B — Resuming work**: an analysis file exists. Load it for context before doing anything else.
- **Mode C — Mid-work update**: a finding during work changes the analysis. Update the file.

## Writing Principle

**Write for a newcomer.** The ticket document must ALWAYS be written so that someone who is not familiar with the
ticket, the project, the code, or anything related can read it and fully understand:

- The business context and why this work matters
- How the relevant parts of the system currently work (concepts, terminology, data flows)
- What the problem is and why it exists
- What data sources or code paths are involved, with enough detail to understand them
- What the approved solution is and why it was chosen

Never assume the reader has prior knowledge. Explain terminology, describe how things work before explaining what's
broken, and provide enough context that a new team member could pick up the ticket and continue the work without asking
clarifying questions.

## Step 0 — confirm intent on ambiguous triggers

If the skill loaded because the user mentioned a ticket ID or phrasing that could be either ticket work or a
status/historical/comparative reference, ask the user to confirm before doing anything else. A single short question is
enough: "Are you starting/resuming work on `<TICKET_ID>` now, or just referring to it?" Do not load files, investigate
the codebase, or write anything until the user confirms they are doing work. If they say no, exit cleanly without side
effects.

Skip this step when intent is unambiguous — explicit `/ticket` invocation, "starting a new ticket", "continue with
`<ID>`", and similar clear signals do not need confirmation.

## Step 1 — establish the ticket ID

If the user provided a ticket ID in their message or as an argument, use it. Otherwise, ask the user for the ticket ID
and stop until they provide one. Do not invent or guess an ID.

Once you have the ID, refer to it as `<TICKET_ID>` for the rest of this skill. Each ticket has its own directory at
`.claude/docs/tickets/<TICKET_ID>/`, containing two files:

- `ANALYSIS.md` — the analysis document (problem, options, recommendation, decisions).
- `PLAN.md` — the implementation plan (phases, current phase, branch, status).

## Step 2 — pick the mode

Check whether the directory `.claude/docs/tickets/<TICKET_ID>/` exists and what is in it.

- **Directory does not exist** → Mode A.
- **Directory exists and the user is starting work or asking for context** → Mode B.
- **Directory exists and a new finding has emerged during work** → Mode C.

## Mode A — Create the analysis file

Run these substeps before writing or editing any application code.

### A.1 — Get the ticket content

The ticket file requires both a **description** (what the ticket is about) and **acceptance criteria** (what "done"
looks like). If either is missing from the conversation, ask the user for whichever is missing and stop until they
provide it. Do not invent ticket content. Do not proceed with investigation or file creation until both are in hand.

### A.2 — Investigate before writing

Investigate the codebase to ground the analysis in real files, functions, and current behavior. Cite
`file_path:line_number` for any code referenced.

For bug-type tickets, attempt to reproduce or directly observe the reported behavior. If you cannot reproduce, say so
explicitly in the document under "Reproduction / evidence". For feature or refactor tickets, reproduction does not
apply — note the existing behavior you are changing instead.

#### A.2.1 — Investigation checklist

Before concluding that you understand the problem space, verify you have covered these angles:

1. **Search by field/concept name, not just table/class purpose**: If you need data X, grep the entire codebase for
   field names that could hold X. Data often lives in tables whose primary purpose differs from your use case.
   ```bash
   grep -rn "<fieldName>\|<alternativeName>" --include="*.java"
   ```

2. **Trace both creation and deletion paths**: If data disappears on event A, also trace what happens when that data was
   created. The creation path may write to stores that survive the deletion.

3. **Check existing dependencies in the target file**: Before proposing new data sources, look at what the file you plan
   to modify already imports. The answer may be one existing injection away.

4. **Check what related endpoints already return**: If a similar endpoint exists (e.g., v4 when building v5), examine
   what data sources it uses and whether they contain what you need.

5. **Ask what persists vs. what is transient**: For any data you assume is "deleted" or "cleared," verify there isn't a
   secondary copy, audit log, or history table that retains it.

### A.3 — Write the analysis file

Write `.claude/docs/tickets/<TICKET_ID>/ANALYSIS.md` using the template below. Replace `<TICKET_ID>` and `<YYYY-MM-DD>`
with the real values.

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

<For bugs: steps to reproduce or the observation that confirms the problem. If unverified, say so. For
features/refactors: existing behavior being changed.>

## Root cause hypothesis

<Best current explanation. Mark as hypothesis until confirmed. Omit for pure feature work.>

## Data sources

<Tables, APIs, caches, or other data stores relevant to this ticket. For each source, document: name, key fields, what
it captures, and any limitations. This section grounds the analysis in concrete data structures and helps newcomers
understand where information lives.>

## Constraints

<Anything that narrows the solution space: APIs that cannot change, performance budgets, deadlines, dependencies,
conventions in this repo.>

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

<Which option and why. Lead with the strongest opposing case against the recommendation before defending it.>

## Open questions

<Things that must be answered before implementation. If none, write "none". When a question is answered, remove it from
this section and incorporate the answer into the relevant section above (e.g., Data sources, Constraints, or the chosen
Option).>
```

### A.4 — Wait for the user to choose

After writing the file, summarize the recommended option in one or two sentences and ask the user which option to
proceed with.

**Do not start implementation until the user explicitly chooses an option from the document.**

### A.5 — Create PLAN.md once an option is chosen

Once the user chooses an option, create `.claude/docs/tickets/<TICKET_ID>/PLAN.md`. Apply the same writing principle: a
newcomer must be able to read this file and understand exactly where the work currently stands.

PLAN.md must contain at minimum:

- **Branch** — the git branch the work is being done on. If the branch does not yet exist, propose a name and confirm
  with the user before creating it. Update this field if the branch changes.
- **Current phase** — which phase is in progress. Keep this field accurate as work moves forward.
- **Status summary** — one or two sentences a newcomer can read to know what is happening right now (e.g. "Phase 2 in
  progress; data-access layer wired up, integration tests pending").
- **Phases** — an ordered list of implementation phases. Each phase must be the **smallest meaningfully testable code
  change** — small enough to verify in isolation, but large enough that the verification is meaningful: the phase
  produces an observable, checkable behavior change (a passing test, a queryable DB row, a working endpoint, a
  successful build with new behavior). A phase like "add an empty class with no behavior" does not qualify on its own;
  fold it into the next phase that gives it observable behavior. Use as many or as few phases as the work actually
  requires — a small ticket may need only one or two, a large one may need several. Do not pad with phases that aren't
  real units of work. For each phase: name, goal, files/areas affected, how it will be verified, and a status marker (
  `pending` / `in progress` / `done`). **Prerequisite bugs**: If investigation reveals bugs that must be fixed before
  the main feature can work, include them as early phases in PLAN.md (e.g., "Phase 1 — Fix X", "Phase 2 — Fix Y", "Phase
  3 — Implement feature"). This keeps all work for the ticket in one traceable plan.
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

Keep PLAN.md updated continuously as work progresses — `Current phase`, `Status summary`, and per-phase status markers
must always reflect reality. A stale PLAN.md is worse than none.

## Mode B — Resume work from existing analysis

The user is continuing work on a ticket whose directory already exists.

1. Read **both** files in full before answering, suggesting changes, or making edits:
    - `.claude/docs/tickets/<TICKET_ID>/ANALYSIS.md` for problem, options, and decisions.
    - `.claude/docs/tickets/<TICKET_ID>/PLAN.md` for current phase, branch, and status.
2. Confirm the active git branch matches the branch named in PLAN.md. If it does not, surface the discrepancy and ask
   before doing any work — do not silently switch or assume.
3. Use these files as the source of truth for the problem, constraints, chosen option, current phase, and open
   questions. Do not re-derive what is already documented.
4. If the user's current request conflicts with what is documented (different option, different phase ordering, etc.),
   surface the conflict and ask before proceeding. Do not silently override.
5. If PLAN.md is missing but the analysis file exists, the ticket was created before the plan stage existed or the plan
   was never created — offer to create PLAN.md now using A.5.
6. If you discover during this work that either file is wrong or incomplete, switch to Mode C.

## Mode C — Update the analysis file with new findings

During work on a ticket, update `.claude/docs/tickets/<TICKET_ID>/ANALYSIS.md` whenever a **material** finding emerges.
A finding is material if it does at least one of:

- Changes the **direction** of the work (different approach than what was chosen).
- Changes the **scope** of the work (adds, removes, or reshapes what is being delivered).
- Changes or invalidates a documented constraint.
- Rules out an option, or surfaces a new option.
- Changes the recommendation or the chosen option.
- Reveals a root cause that contradicts the prior hypothesis.
- Answers an item in "Open questions" or adds a new one.

Do **not** update the file for routine progress, minor observations, or anything already implied by the existing
content. The file is a planning artifact, not a work log.

When you do update:

1. Edit the relevant section in place. Preserve the existing structure.
2. If a documented decision, direction, or scope changes, briefly note what changed and why in the "Recommendation" or "
   Open questions" section — enough that a future reader can reconstruct the reasoning.
3. Tell the user what you changed in the file and why, in one or two sentences. Do not paste the full diff.

### Keeping PLAN.md current

PLAN.md must reflect reality at all times. Update it whenever:

- A phase changes status (`pending` → `in progress` → `done`).
- The current phase or status summary changes.
- The branch changes.
- A material implementation decision is made — append to the decisions log with the date and one-line reason.
- A direction or scope change in the analysis file invalidates the planned phases — revise the phases to match.

Each phase remains a smallest meaningfully testable change. If a phase grows during work, split it.

### Scope boundary — what belongs in the ticket file vs. project docs

The ticket file is **only** for analysis specific to this ticket: the problem, the options considered, the chosen
direction, the trade-offs, and ticket-specific findings.

**Durable technical information discovered during ticket work belongs in the project docs, not the ticket file.**
Examples:

- A new external integration, schema, or store → project docs.
- A previously undocumented setup step, credential, or environment variable → project docs.
- An architecture detail, error pattern, or debugging technique that future work will need → project docs.
- A verified command or troubleshooting fix not already documented → project docs.

To decide whether durable information goes in `SETUP.md` or `TECHNICAL.md`, follow the routing rules in
`.claude/docs/CLAUDE.md`. If a finding is genuinely both ticket-relevant *and* durable (e.g. it shapes this ticket's
solution AND future work needs it), update **both** files: a ticket-specific framing in the ticket file, and a
project-level entry in the appropriate project doc.

If `SETUP.md` or `TECHNICAL.md` does not yet exist, follow the generation guidance in `.claude/docs/CLAUDE.md` rather
than skipping the update or dumping the content into the ticket file. Verify before writing, per that file's
verification standards.

If you are uncertain which file a finding belongs in, ask the user before writing. Do not guess silently.

## Rules

- Do not skip the investigation step in Mode A. An analysis built only from the ticket text is not useful.
- Every option must be a real option. Do not pad with strawmen.
- If you genuinely see only one viable option, say so and explain why alternatives were rejected — do not invent fake
  alternatives.
- In Mode B, read both files before answering. Do not skim or guess at their contents.
- In Mode C, update only on material findings. Do not turn the file into a work log.
- Keep PLAN.md current — `Current phase`, `Status summary`, branch, and per-phase status markers must always reflect
  reality.
- Keep ticket-specific analysis in the ticket file. Keep durable technical and setup information in the project docs (
  `SETUP.md` / `TECHNICAL.md`), routed per `.claude/docs/CLAUDE.md`.
- General commit conventions live in the project root `CLAUDE.md` and still apply.

## Ticket commit rules

These apply on top of the general commit conventions in the project root `CLAUDE.md` (which already covers the
`<TICKET_ID>: ...` subject-line prefix).

1. **Keep PLAN.md current at commit time.** If a commit completes any PLAN.md phases, mark each completed phase as
   `done` and refresh `Current phase` and `Status summary` accordingly. The PLAN.md update must land before or as part
   of the same commit. Stale phase markers defeat the purpose of the plan.
