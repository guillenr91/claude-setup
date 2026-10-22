---
name: code-review-rigor
description: >-
  Rules for reviewing pending code changes: breadth-to-scope matching, effort
  level, finding triage, re-review, and review summary. Invoke for any code
  review — pre-commit, pre-PR, reviewing someone else's PR, or ad-hoc analysis
  of pending changes. Other skills (commit-review, manage-pull-request) invoke
  this skill; invoke it directly when the user asks for a code review without
  hitting one of their triggers. Do not invoke for read-only inspection
  (`git status`, `git log`, `git diff`) when no review is being produced.
---

# Code Review Rigor Skill

Apply the global `# Context` brevity and formatting rules to this file.

Applies review breadth, effort, triage, and reporting rules to every code review, regardless of trigger.

0. Establish business context before reviewing code. Identify the intended business purpose, actors, rules, acceptance criteria, scope boundaries, and expected behavior from the PR or ticket description, linked ticket, Confluence page, diagram, technical specification, or another authoritative artifact. Read the source materials, reconcile contradictions, and distinguish requirements from implementation assumptions.

   If the available materials do not establish the business purpose and rules needed to validate the change, ask the operator for the specific ticket URL, Confluence page, diagram, technical specification, or other resource required. Ask a precise question naming the missing business rule or decision. Do not infer business intent from the changed code, branch name, or a plausible implementation. Pause the review until the material gap is resolved; do not claim the change aligns with business requirements without direct evidence.

   Compare each changed business behavior, boundary condition, and error path against the verified purpose, rules, and acceptance criteria. Treat an implementation that conflicts with those sources or lacks proof of a required behavior as a candidate concern and send it through Rule 3.

1. Match review breadth to change scope. For EVERY review, enumerate every available review capability before writing findings, then use every applicable capability. Do not stop at your own read or omit an available tool or skill because the change looks small. For trivial changes (typo fixes in comments/docs, formatting-only edits, comment-only edits, dead-link updates, version bumps in non-runtime config), skip only capabilities that cannot examine the change and state why; when in doubt, run the check.

   Enumeration is mandatory. Produce the list in chat, then execute — do not skip a capability because you have a hunch about the diff. Check each:

   - Review skills: run `Skill` listing / `<available skills>` in the environment. Invoke every review-shaped skill that applies (e.g. `coderabbit:code-review`, `code-review`, `security-review`, and any project-scoped review skill). Run in parallel when independent.
   - Review sub-agents: check `Available agent types`. Launch `code-reviewer` (and any repo-specific reviewer agent) when it exists.
   - Review MCPs / plugins: e.g. `coderabbit`, `code-review`, project-configured static analyzers, IDE diagnostics (`mcp__ide__getDiagnostics`, `mcp__idea__lint_files`, `mcp__idea__get_file_problems`), grep/lint runners.
   - Project scripts: repo-local `test`, `lint`, `check`, `typecheck` commands surfaced by CLAUDE.md, README, or ticket context.
   - Language checks and local verification commands (test suite, compile, static analyzer, formatter --check) when they apply.
   - Style guides: inspect `.claude/styles/CLAUDE.md`, map every changed file to its applicable guide, read each guide before reviewing that file, and verify the diff against its rules. For example, review every `.java` file against `JAVA.md` and every Markdown file against `MARKDOWN.md`. For a changed file without a matching guide, record that no matching guide exists; do not assume a different guide applies.

   After the run, consolidate findings into one deduplicated list, then apply the evidence-first verification pass in step 3 to each finding.

   Always perform the reuse audit required by the global `# Engineering standards`: for each added method, class, helper, utility, feature, or dependency, search existing symbols, neighboring modules, relevant callers, prior implementations, and applicable installed libraries. Read candidate implementations and their callers or documentation to establish whether they fit. A change that reinvents existing code or library functionality is a candidate finding; absence of scan evidence is not proof that reuse was impossible.

   Also verify the change against the remaining `# Engineering standards` — local-pattern match (`Match local patterns`), prior-implementation alignment (`Align with prior implementations`), plus other applicable standards. Violations become findings and go through the falsification and triage passes. Do not restate those rules here — read them from the global instructions so they stay authoritative in one place.

2. Use the highest effort level the task warrants. Default higher when the change touches security, data, auth, public APIs, or shared infrastructure.
3. Falsify every candidate finding before it becomes a review finding. Popperian falsification, not verify-your-own-claim: for each candidate, name the single piece of in-session evidence that would prove the concern WRONG, then collect it. Findings survive by surviving the falsification attempt, not by being raised. Skipping this produces false-positive comments the operator has to filter later.

   Concrete falsification moves — pick the one(s) that would kill the finding:

   - Wire format / API contract: read the RECEIVER's DTO / handler / OpenAPI spec, including in sibling repos when the receiver lives elsewhere. Not the sender comment. Not "usually a service does X".
   - Caller assumption: open the actual callers (`Grep`, IDE Find Usages, `git grep`), not one representative caller.
   - Null / boundary / edge case: read the guard that would prevent it (if any), and the test that would exercise it. Test exists and passes → likely falsified.
   - "This rename / signature change breaks callers": grep for the old name AND the new signature across every module that could import it.
   - Race / atomicity: read the synchronization primitives, transaction boundaries, or claim / fence code — do not infer from surrounding structure.
   - Performance / cost: read the caller cadence and the code path in full. If the alleged redundant work is gated upstream, falsified.
   - Missing test: `git grep` the class/method name in `**/*Test*` and read the assertions — names lie.
   - Config / flag / env value: read the config file, `git log` on it, and any related LaunchDarkly / feature-flag definition. Do not guess defaults.

   Rules:

   - Apply `evidence-first` to the collected evidence — quote path:line, paste command output, or cite the fetched URL inline in your working notes for each finding.
   - Drop any finding whose falsifying evidence you cannot obtain in-session — do NOT carry it forward as an "unverified concern" for the operator to filter. If important enough, get the evidence; if you can't, drop silently.
   - Drop any finding the falsification pass actually falsified — record the falsifying evidence in your working notes but do NOT show it to the operator, include it in the triage table, or mention it in the summary. The operator's triage input is the surviving-after-falsification list only.
   - Only findings that survived a real attempt to disprove them proceed to the review output.
4. Triage every surviving verified finding only after it has completed Rule 3. Do not put a hypothesis, unverified concern, or falsified concern in the table. Do not apply a fix, dismiss a verified concern, or select a review outcome before presenting the table and receiving the operator's choice. The first operator-facing output after a review pass must be this table, with one row per surviving concern and `#` starting at 1:

   ```markdown
   | # | Comment | Trigger | Impact | Blocking? |
   |---|---------|---------|--------|-----------|
   | 1 | <2–4 word slug> | <concrete condition to hit it> | <what breaks or degrades> | <Yes/No — one-line reason> |
   ```

   - `Comment`: 2–4 words, no code identifiers or backticks.
   - `Trigger`: one sentence naming the inputs, state, configuration, or path that causes the concern.
   - `Impact`: one sentence naming the concrete behavior, data, cost, or workflow effect established by the evidence.
   - `Blocking?`: `Yes — <reason>` or `No — <reason>`; explain why the concern does or does not block the reviewed change.
   - Include every verified survivor, do not pre-filter it, and omit inline-comment bodies, file paths, line numbers, and verdict rationale. If none survive, show the table with no finding rows and state `No verified concerns.`
   - Stop after the table and wait for the operator to select rows to keep or ignore. The operator has the final decision. Only after that choice, apply selected fixes or record an explicit skip reason (out of scope, conflicts with a stated requirement, or operator decision). No silent ignores.
   - For PR reviews, immediately follow the table with the recommended no-verdict or verdict event from `manage-pull-request`, and one short line for skipped capabilities, if any; then wait for the operator's selection before drafting comment bodies. The PR skill owns the later GitHub-specific drafting and posting steps.
5. Re-run the review after fixes when changes are non-trivial, to confirm resolution and no new issues.
6. Summarize the review pass in the commit message, PR description, or final response: the business-context sources and verified business purpose, every capability used, every applicable style guide, the reuse audit, business-alignment validation, how many candidate concerns were falsified, the verified-concerns table, what was fixed, and what was deferred and why.
