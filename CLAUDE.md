# Project Instructions

Loaded into context. Keep concise, explicit, and actionable for AI agents. No decorative formatting around prose
(no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

## Context routing

Before answering or acting, read [.claude/context/CLAUDE.md](.claude/context/CLAUDE.md) and use it to choose which
project context files to load.

Keep this file portable: route only to `SETUP.md` and `TECHNICAL.md`. Project-specific runbooks (env, deployment, etc.)
should be referenced from `SETUP.md` or `TECHNICAL.md` instead.

## Style guides

Before creating or modifying style guides, read [.claude/styles/CLAUDE.md](.claude/styles/CLAUDE.md).

Before generating or reviewing work in a domain covered by `.claude/styles/`, read the matching style guide first:

- Java code → [JAVA.md](.claude/styles/JAVA.md)
- Postman collections, requests, environments, scripts → [POSTMAN.md](.claude/styles/POSTMAN.md)
- Any other domain with a Markdown file in `.claude/styles/` → that file.

## Dependency changes

Before adding any package, library, image dependency, CLI tool, OS package, or build/runtime dependency:

1. Identify the exact behavior that requires it.
2. Verify the minimal dependency set locally when feasible. Vendor docs prove how to install something; they do not
   prove every package in an example is required here.
3. Add extras only after proving the minimal install or existing project tooling cannot satisfy the need.
4. Default-reject development headers, SDKs, compilers, `*-dev` packages, and build tools in runtime images unless a
   compile step or runtime behavior proves they are required.
5. Record proof in ticket notes, durable docs, commit message, or final response: command run, output observed, source
   inspected, or explicit reason verification was not possible.

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

## Pre-commit / pre-PR review

Triggers immediately before running `git commit`, `git push`, or opening a PR (`gh pr create`). Does not trigger
when only drafting a commit message or PR description without executing the command.

When triggered, run a comprehensive code review on the pending changes and resolve findings — every time, even when
the change feels small.

1. Run every code review capability available. Use the highest effort level the task warrants.
2. Triage every finding: apply the fix, or record an explicit skip reason (false positive, out of scope, conflicts
   with stated requirement). No silent ignores.
3. Re-run the review after fixes when changes are non-trivial, to confirm resolution and no new issues.
4. Summarize the review pass in the commit message, PR description, or final response: what was reviewed, how many
   findings surfaced, what was fixed, what was deferred and why.

## PR review feedback

The goal of every review comment is to help the developer improve their code or solve a detected issue. Comments that
only point out problems without providing a path forward are not useful. Every comment should enable the developer to
take immediate action.

When reviewing a PR:

- Calibrate state to impact. `REQUEST_CHANGES` only for clear breakage, security risk, data loss, or behavior
  likely to harm a workflow. Edge cases, hardening, polish, doc gaps, and low-risk maintainability are non-blocking
  unless evidence shows they break a supported workflow. For additive PRs that don't break existing behavior, state
  the risk plainly and say whether it should block.
- Prefix every comment title with an uppercase category in brackets: `[BUG]`, `[SECURITY]`, `[TEST]`, `[DOCS]`,
  `[MAINTAINABILITY]`. Use `[LEGACY BUG]` for pre-existing issues — note them, but they don't block approval unless
  the PR makes them worse.
- Each comment must be actionable: state the issue, explain why it matters, and provide the solution. The developer
  should be able to resolve the comment without further clarification.
- Do not call a change unsafe, broken, or workflow-impacting unless the evidence supports that severity.
- Prefer fewer, higher-signal comments. Combine findings that share a root cause or fix.

Posting review comments:

1. Post inline comments FIRST on specific code lines for each finding. Use the GitHub API to create review comments
   with the exact diff position. To find the position, run `gh pr diff <PR> --patch | grep -n "<unique text>"` to
   get the line number in the diff, then use that as the `position` parameter.
2. Every inline comment MUST include a code suggestion when a fix is possible. Use GitHub's suggestion block format:
   ```suggestion
   // corrected code here
   ```
   This allows the author to apply the fix with one click. Only omit suggestions for observations that have no
   concrete fix (e.g., questions, design discussions, or findings that require broader refactoring).
3. Post ONE general summary comment LAST with the approval or request-changes verdict. This summary should:
    - List what was verified (claims tested, tests run, code paths checked).
    - Briefly reference the inline comments already posted (do not repeat full details).
    - State the overall verdict and reasoning.
4. Never post only a general comment without inline comments when there are specific code-level findings.
5. Before posting, confirm with the user whether the review should approve or request changes when not already
   explicit.
