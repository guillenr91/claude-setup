---
name: code-review-effort
description: >-
  Rules for reviewing pending code changes: breadth-to-scope matching, effort
  level, finding triage, re-review, and review summary. Invoke for any code
  review — pre-commit, pre-PR, reviewing someone else's PR, or ad-hoc analysis
  of pending changes. Other skills (commit-review, manage-pull-request) invoke
  this skill; invoke it directly when the user asks for a code review without
  hitting one of their triggers. Do not invoke for read-only inspection
  (`git status`, `git log`, `git diff`) when no review is being produced.
---

# Code Review Effort Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Applies review breadth, effort, triage, and reporting rules to every code review, regardless of trigger.

1. Match review breadth to change scope. For non-trivial changes — anything that touches code that runs at
   runtime, tests, build, infra, public APIs, security, data, or auth — enumerate every review capability
   available in this environment BEFORE writing the review, then run every applicable one. Do not stop at your own
   read. For trivial changes (typo fixes in comments or docs, formatting-only edits, comment-only edits, dead-link
   updates, version bumps in non-runtime config) run a proportional subset and state in the review summary what was
   skipped and why. When in doubt, treat the change as non-trivial.

   Enumeration is mandatory. Produce the list in chat, then execute — do not skip a capability just because you
   already have a hunch about the diff. Check each of the following:

   - Review skills: run `Skill` listing / `<available skills>` in the environment. Invoke every review-shaped skill
     that applies to the diff, e.g. `coderabbit:code-review`, `code-review`, `security-review`, and any project-
     scoped review skill named in the available-skills list. Run them in parallel when they do not depend on each
     other's output.
   - Review sub-agents: check `Available agent types` in the environment. Launch `code-reviewer` (and any repo-
     specific reviewer agent) when it exists.
   - Review MCPs / plugins: e.g. `coderabbit`, `code-review`, project-configured static analyzers, IDE
     diagnostics (`mcp__ide__getDiagnostics`, `mcp__idea__lint_files`, `mcp__idea__get_file_problems`), grep/lint
     runners.
   - Project scripts: repo-local `test`, `lint`, `check`, `typecheck` commands surfaced by CLAUDE.md, README, or
     the ticket context.
   - Language checks and local verification commands (test suite, compile, static analyzer, formatter --check)
     when they apply to the changed files.

   After the run, consolidate findings from every source into one deduplicated list, then apply the evidence-first
   verification pass in step 3 to each finding before drafting output.

2. Use the highest effort level the task warrants. Default to higher effort when the change touches security,
   data, auth, public APIs, or shared infrastructure.
3. Falsify every candidate finding before it becomes a review finding. This is a Popperian falsification pass, not
   a verify-your-own-claim pass: for each candidate, name the single piece of in-session evidence that would prove
   the concern WRONG, then go collect it. Findings survive by surviving the falsification attempt, not by having
   been raised. Skipping this step is what produces false-positive comments the operator has to filter later.

   Concrete falsification moves — pick the one(s) that would kill the finding:

   - Concern about a wire format / API contract: read the RECEIVER's DTO / handler / OpenAPI spec, including in
     sibling repos when the receiver lives elsewhere. Not the sender comment. Not "usually a service does X".
   - Concern about a caller assumption: open the actual callers (`Grep`, IDE Find Usages, `git grep`), not one
     representative caller.
   - Concern about a null / boundary / edge case: read the guard that would prevent it (if any), and the test
     that would exercise it. If the test exists and passes, the finding is likely falsified.
   - Concern about "this rename / signature change breaks callers": grep for the old name AND the new signature
     across every module that could import it.
   - Concern about a race / atomicity: read the synchronization primitives, transaction boundaries, or claim /
     fence code — do not infer from surrounding structure.
   - Concern about performance / cost: read the caller cadence and the code path in full. If the alleged
     redundant work is actually gated upstream, the concern is falsified.
   - Concern about a missing test: `git grep` the class/method name in `**/*Test*` and read the assertions —
     names lie.
   - Concern about a config / flag / env value: read the config file, `git log` on it, and any related
     LaunchDarkly / feature-flag definition. Do not guess default states.

   Rules:

   - Apply `evidence-first` to the collected evidence — quote path:line, paste command output, or cite the
     fetched URL inline in your working notes for each finding.
   - Drop any finding whose falsifying evidence you cannot obtain in-session — do NOT carry it forward as an
     "unverified concern" for the operator to filter. If it is important enough to keep, first go get the
     evidence; if you cannot, drop it silently.
   - Drop any finding that the falsification pass actually falsified — record the falsifying evidence in your
     working notes but do NOT show the finding to the operator, do NOT include it in the triage table, do NOT
     mention it in the summary. The operator's triage input is the surviving-after-falsification list only.
   - Only findings that survived a real attempt to disprove them proceed to the review output.
4. Triage every finding: apply the fix, or record an explicit skip reason (false positive, out of scope, conflicts
   with stated requirement). No silent ignores.
5. Re-run the review after fixes when changes are non-trivial, to confirm resolution and no new issues.
6. Summarize the review pass in the commit message, PR description, or final response: what was reviewed
   (name every capability actually run), how many findings surfaced, what was fixed, what was deferred and why.