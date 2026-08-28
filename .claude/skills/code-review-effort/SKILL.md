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
   runtime, tests, build, infra, public APIs, security, data, or auth — first discover the review capabilities
   available in the current environment, then use every applicable capability. Include available tools, skills,
   sub-agents, project scripts, language checks, and local verification commands when they apply. For trivial changes
   (typo fixes in comments or docs, formatting-only edits, comment-only edits, dead-link updates, version bumps in
   non-runtime config) run a proportional subset and state in the review summary what was skipped and why. When in
   doubt, treat the change as non-trivial.
2. Use the highest effort level the task warrants. Default to higher effort when the change touches security,
   data, auth, public APIs, or shared infrastructure.
3. Triage every finding: apply the fix, or record an explicit skip reason (false positive, out of scope, conflicts
   with stated requirement). No silent ignores.
4. Re-run the review after fixes when changes are non-trivial, to confirm resolution and no new issues.
5. Summarize the review pass in the commit message, PR description, or final response: what was reviewed, how many
   findings surfaced, what was fixed, what was deferred and why.