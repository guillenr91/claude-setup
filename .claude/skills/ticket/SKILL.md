---
name: ticket
description: Manage the ticket analysis document at .claude/docs/tickets/<TICKET_ID>.md across the full lifecycle of a ticket — create it before any code changes, read it for context on resumed work, and keep it updated as findings change. TRIGGER when the user explicitly invokes /ticket, OR signals starting a new ticket ("I have to work on a new ticket", "I was assigned a new ticket", "we need to work on a ticket", "there is a ticket I need to work on", "starting a new ticket", "picking up ticket <ID>"), OR signals resuming work on a ticket ("continue with ticket <ID>", "back to <ID>", "let's keep working on <ID>"), OR mentions a ticket-shaped ID (e.g. "ABC-123", "PROJ-4567") in the context of doing work on it. Do NOT trigger for general code questions unrelated to a specific ticket.
---

# Ticket lifecycle

You are working on a ticket. This skill covers three modes — pick the one that matches the situation, then follow its steps.

- **Mode A — New ticket**: no analysis file exists yet. Create it.
- **Mode B — Resuming work**: an analysis file exists. Load it for context before doing anything else.
- **Mode C — Mid-work update**: a finding during work changes the analysis. Update the file.

## Step 1 — establish the ticket ID

If the user provided a ticket ID in their message or as an argument, use it. Otherwise, ask the user for the ticket ID and stop until they provide one. Do not invent or guess an ID.

Once you have the ID, refer to it as `<TICKET_ID>` for the rest of this skill. The target file is always `.claude/docs/tickets/<TICKET_ID>.md`.

## Step 2 — pick the mode

Check whether `.claude/docs/tickets/<TICKET_ID>.md` already exists.

- **File does not exist** → Mode A.
- **File exists and the user is starting work or asking for context** → Mode B.
- **File exists and a new finding has emerged during work** → Mode C.

## Mode A — Create the analysis file

Run these substeps before writing or editing any application code.

### A.1 — Get the ticket content

The ticket file requires both a **description** (what the ticket is about) and **acceptance criteria** (what "done" looks like). If either is missing from the conversation, ask the user for whichever is missing and stop until they provide it. Do not invent ticket content. Do not proceed with investigation or file creation until both are in hand.

### A.2 — Investigate before writing

Investigate the codebase to ground the analysis in real files, functions, and current behavior. Cite `file_path:line_number` for any code referenced.

For bug-type tickets, attempt to reproduce or directly observe the reported behavior. If you cannot reproduce, say so explicitly in the document under "Reproduction / evidence". For feature or refactor tickets, reproduction does not apply — note the existing behavior you are changing instead.

### A.3 — Write the analysis file

Write `.claude/docs/tickets/<TICKET_ID>.md` using the template below. Replace `<TICKET_ID>` and `<YYYY-MM-DD>` with the real values.

```markdown
---
ticket: <TICKET_ID>
created: <YYYY-MM-DD>
status: analysis
---

# <TICKET_ID>

## Problem
<What is broken or missing, in the user's words plus your verified observations. Cite file_path:line_number for any code referenced.>

## Acceptance criteria
<The conditions that define "done" for this ticket, as provided by the user. List them verbatim or lightly edited for clarity. Do not invent criteria.>

## Reproduction / evidence
<For bugs: steps to reproduce or the observation that confirms the problem. If unverified, say so. For features/refactors: existing behavior being changed.>

## Root cause hypothesis
<Best current explanation. Mark as hypothesis until confirmed. Omit for pure feature work.>

## Constraints
<Anything that narrows the solution space: APIs that cannot change, performance budgets, deadlines, dependencies, conventions in this repo.>

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
<Things that must be answered before implementation. If none, write "none".>
```

### A.4 — Wait for the user to choose

After writing the file, summarize the recommended option in one or two sentences and ask the user which option to proceed with.

**Do not start implementation until the user explicitly chooses an option from the document.**

## Mode B — Resume work from existing analysis

The user is continuing work on a ticket whose analysis file already exists.

1. Read `.claude/docs/tickets/<TICKET_ID>.md` in full before answering, suggesting changes, or making edits.
2. Use the file as the source of truth for the problem, constraints, chosen option, and open questions. Do not re-derive what is already documented.
3. If the user's current request conflicts with the file (e.g. they want a different option than the one chosen), surface the conflict and ask before proceeding. Do not silently override the documented decision.
4. If you discover during this work that the file is wrong or incomplete, switch to Mode C.

## Mode C — Update the analysis file with new findings

During work on a ticket, update `.claude/docs/tickets/<TICKET_ID>.md` whenever a **material** finding emerges. A finding is material if it does at least one of:

- Changes the **direction** of the work (different approach than what was chosen).
- Changes the **scope** of the work (adds, removes, or reshapes what is being delivered).
- Changes or invalidates a documented constraint.
- Rules out an option, or surfaces a new option.
- Changes the recommendation or the chosen option.
- Reveals a root cause that contradicts the prior hypothesis.
- Answers an item in "Open questions" or adds a new one.

Do **not** update the file for routine progress, minor observations, or anything already implied by the existing content. The file is a planning artifact, not a work log.

When you do update:

1. Edit the relevant section in place. Preserve the existing structure.
2. If a documented decision, direction, or scope changes, briefly note what changed and why in the "Recommendation" or "Open questions" section — enough that a future reader can reconstruct the reasoning.
3. Tell the user what you changed in the file and why, in one or two sentences. Do not paste the full diff.

### Scope boundary — what belongs in the ticket file vs. project docs

The ticket file is **only** for analysis specific to this ticket: the problem, the options considered, the chosen direction, the trade-offs, and ticket-specific findings.

**Durable technical information discovered during ticket work belongs in the project docs, not the ticket file.** Examples:

- A new external integration, schema, or store → project docs.
- A previously undocumented setup step, credential, or environment variable → project docs.
- An architecture detail, error pattern, or debugging technique that future work will need → project docs.
- A verified command or troubleshooting fix not already documented → project docs.

To decide whether durable information goes in `SETUP.md` or `TECHNICAL.md`, follow the routing rules in `.claude/docs/CLAUDE.md`. If a finding is genuinely both ticket-relevant *and* durable (e.g. it shapes this ticket's solution AND future work needs it), update **both** files: a ticket-specific framing in the ticket file, and a project-level entry in the appropriate project doc.

If `SETUP.md` or `TECHNICAL.md` does not yet exist, follow the generation guidance in `.claude/docs/CLAUDE.md` rather than skipping the update or dumping the content into the ticket file. Verify before writing, per that file's verification standards.

If you are uncertain which file a finding belongs in, ask the user before writing. Do not guess silently.

## Rules

- Do not skip the investigation step in Mode A. An analysis built only from the ticket text is not useful.
- Every option must be a real option. Do not pad with strawmen.
- If you genuinely see only one viable option, say so and explain why alternatives were rejected — do not invent fake alternatives.
- In Mode B, read the file before answering. Do not skim or guess at its contents.
- In Mode C, update only on material findings. Do not turn the file into a work log.
- Keep ticket-specific analysis in the ticket file. Keep durable technical and setup information in the project docs (`SETUP.md` / `TECHNICAL.md`), routed per `.claude/docs/CLAUDE.md`.
