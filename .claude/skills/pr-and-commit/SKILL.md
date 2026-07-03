---
name: pr-and-commit
description: >-
  Commit conventions, code review effort, pre-commit/pre-PR review, GitHub
  draft-first gate, and PR review feedback rules. Invoke before running
  `git commit`, `git push`, `gh pr create`, `gh pr edit`, submitting a PR
  review, posting inline review comments or replies, and creating or
  commenting on issues. Also invoke when the user asks to draft a commit
  message, PR description, or PR review. Do not invoke for read-only git
  operations (`git status`, `git log`, `git diff`).
---

# PR and Commit Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Applies commit conventions, review effort, GitHub write-action gate, and PR review feedback rules.

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

## Code review effort

Applies to every code review — pre-commit, pre-PR, reviewing someone else's PR, or ad-hoc analysis of pending
changes. The two subsections below specialise this rule to specific triggers; the rule itself lives here.

1. Match review breadth to change scope. For non-trivial changes — anything that touches code that runs at
   runtime, tests, build, infra, public APIs, security, data, or auth — run every code review capability
   available. Use every coding tool at your disposal: built-in tools, subagents, any code-review skills present
   in the session, language-specific linters and type checkers, and any project-specific verification scripts.
   For trivial changes (typo fixes in comments or docs, formatting-only edits, comment-only edits, dead-link
   updates, version bumps in non-runtime config) run a proportional subset and state in the review summary
   what was skipped and why. When in doubt, treat the change as non-trivial.
2. Use the highest effort level the task warrants. Default to higher effort when the change touches security,
   data, auth, public APIs, or shared infrastructure.
3. Triage every finding: apply the fix, or record an explicit skip reason (false positive, out of scope, conflicts
   with stated requirement). No silent ignores.
4. Re-run the review after fixes when changes are non-trivial, to confirm resolution and no new issues.
5. Summarize the review pass in the commit message, PR description, or final response: what was reviewed, how many
   findings surfaced, what was fixed, what was deferred and why.

## Pre-commit / pre-PR review

Triggers immediately before running `git commit`, `git push`, or opening a PR (`gh pr create`). Does not trigger
when only drafting a commit message or PR description without executing the command.

When triggered, apply the rules in `## Code review effort` above to the pending changes — every time, even when
the change feels small.

## GitHub write actions: draft-first gate

Applies to every action that creates or modifies content visible on GitHub: opening a PR (`gh pr create`), editing
a PR title or description (`gh pr edit`), submitting a PR review or any inline review comment (`gh api` POSTs to
`pulls/.../reviews` or `pulls/.../comments`), replying to existing PR review comments (top-level or threaded), and
creating or commenting on issues. Local commits are not covered by this gate; existing commit conventions apply
there.

Never call the relevant API or `gh` write command until the operator has seen the exact draft and explicitly
approved posting. Cover all of:

1. PR creation: draft the title and full body (Summary, Test plan, any other sections) in chat first. Show the
   target base branch and head branch. Wait for explicit approval before running `gh pr create`. Same rule for
   `gh pr edit` against an existing PR title or description.
2. PR review comments: handled by the drafting workflow under `## PR review feedback`. The gate here applies in
   addition to that workflow.
3. PR review replies: when replying to an inline comment thread or a top-level review comment, draft the reply in
   chat first, show which comment it replies to (file, line, original comment text or ID), and wait for explicit
   approval before posting. Same rule for replying to issue comments.

Approval rules:

- Approval must be explicit. "Looks good", "go ahead", "post it", "ship it", or equivalent counts. Do not infer
  approval from silence, from earlier turns, or from prior approvals on different content.
- Approval of one draft does not extend to later edits. After any non-trivial change to the draft, re-confirm.
- For PRs, approval of the draft body covers `gh pr create` only if the title, body, base, and head are all
  unambiguous in the draft. If any of those is missing or ambiguous, confirm separately before posting.
- For PR reviews, approval of the drafted comments covers the verdict (approve vs. request changes) only if the
  verdict is unambiguous in the drafts. Otherwise confirm separately.

If the operator rejects a draft or any part of it, drop the rejected piece. Do not post it anyway, and do not
re-draft a near-duplicate to argue the point.

## PR review feedback

The goal of every review comment is to help the developer improve their code or solve a detected issue. Comments that
only point out problems without providing a path forward are not useful. Every comment should enable the developer to
take immediate action.

Apply `## Code review effort` above before posting any feedback: run every code review capability available, use
every coding tool at your disposal, and use the highest effort level the task warrants. Findings posted as PR
comments must come from that pass, not from a glance at the diff.

When reviewing a PR:

- Calibrate state to impact. `REQUEST_CHANGES` only for clear breakage, security risk, data loss, or behavior
  likely to harm a workflow. Edge cases, hardening, polish, doc gaps, and low-risk maintainability are non-blocking
  unless evidence shows they break a supported workflow. For additive PRs that don't break existing behavior, state
  the risk plainly and say whether it should block.
- Prefix every comment title with an uppercase category in brackets: `[BUG]`, `[SECURITY]`, `[TEST]`, `[DOCS]`,
  `[MAINTAINABILITY]`. Use `[LEGACY BUG]` for pre-existing issues — note them, but they don't block approval unless
  the PR makes them worse.
- Start every inline comment with a brief title line, then a blank line, then the body. The title must include the
  category prefix and summarize the issue in one short sentence.
- Start every summary review body with a brief title line, then a blank line, then the body. The summary title must
  not include a category prefix. It should state the review verdict, such as `Approved`, `Approved with comments`,
  `Requesting changes`, or `Commenting for visibility`.
- Each comment must be actionable: state what you observed, explain why it matters, and offer a path forward. The
  developer should be able to resolve the comment without further clarification.
- Do not call a change unsafe, broken, or workflow-impacting unless the evidence supports that severity.
- Prefer fewer, higher-signal comments. Combine findings that share a root cause or fix.

Tone for review comments:

- Voice: write every comment in first person as the operator (the repository owner). Use "I" to refer to the
  operator, not to yourself. The reviewer agent must be invisible — never say "I (Claude)", "the agent",
  "from my read as an assistant", or anything that breaks the operator-as-reviewer voice. Example:
  "I checked the auth middleware and noticed X — could you verify whether…". The drafts shown to the operator
  for approval use this same voice so the operator can edit before posting.
- Frame findings as observations to verify, not asserted facts. The reviewer's context is incomplete; the author
  has context the reviewer doesn't. Write comments that invite verification rather than declare verdicts.
- Use phrasing like "I want to flag a scenario I couldn't verify on my side", "could you verify whether…",
  "from my read it looks like…", "I noticed X — was that intentional?". Avoid "this is broken", "this will
  fail", "this introduces a bug" unless you have reproduced the failure in this session.
- When you cannot reproduce a concern in-session, say so explicitly and ask the author to confirm or refute.
  State what you'd need to verify it yourself if relevant.
- Suggestions are offers, not orders. "Would you consider…", "up to you — happy to keep it inline if you prefer
  minimal churn" is fine for non-blocking polish. Reserve direct imperative phrasing for issues you have evidence
  for.
- Keep the category prefix (`[BUG]`, `[TEST]`, etc.) on inline comments — the prefix signals severity; the body should
  still invite verification rather than declare it.
- The category does not have to match certainty. A `[BUG]` comment can still open with "possible issue —
  could you verify?". Severity describes potential impact; tone describes confidence.

Posting review comments:

Apply the `## GitHub write actions: draft-first gate` section above before any API call.

Drafting workflow for review comments:

1. Collect every inline finding (code, file, line, suggested fix) and the summary comment in the chat as plain
   text or a structured list before any API call.
2. Show the operator the exact body of each comment, the file and line it will attach to, the suggestion block if
   any, and the proposed verdict.
3. Apply edits the operator requests. If they reject a finding, drop it; do not post it anyway.
4. Only after explicit approval, run the steps below to post.

After approval:

All inline comments and the summary MUST be posted as a single grouped GitHub review — one `POST` to
`/repos/{owner}/{repo}/pulls/{pull_number}/reviews` that embeds every inline comment in the `comments` array
and includes the summary in `body` and the verdict in `event`. Do not call
`/repos/{owner}/{repo}/pulls/{pull_number}/comments` per finding; that creates ungrouped top-level review
comments instead of a single review.

Endpoint and payload schema, verified against the GitHub REST docs for "Create a review for a pull request":

- Method and path: `POST /repos/{owner}/{repo}/pulls/{pull_number}/reviews`.
- Top-level fields: `body` (string), `event` (string), `comments` (array of objects), `commit_id` (string,
  optional — pins the review to a specific commit SHA; omit to use the latest commit on the PR head).
- `event` accepts one of: `APPROVE`, `REQUEST_CHANGES`, `COMMENT`. Omitting `event` creates a `PENDING` review
  that must be submitted later; do not omit it for a normal review submission.
- `body` (top level) is required when `event` is `REQUEST_CHANGES` or `COMMENT`. It may be omitted for `APPROVE`,
  but include it anyway so the verdict carries the summary.
- Each entry in `comments[]` requires `path` and `body`. Positioning fields:
    - `line` (integer) — the file line in the diff to attach the comment to. For multi-line comments, this is
      the last line of the range.
    - `side` (string) — `RIGHT` for additions or unchanged context lines (green or white in the diff), `LEFT`
      for deletions (red in the diff).
    - `start_line` and `start_side` — required together for multi-line comments (unless using `in_reply_to`).
      `start_line` is the first line of the range; `start_side` is `LEFT` or `RIGHT`.
    - `position` (integer) — diff-hunk position, not the file line. GitHub docs mark `position` as closing down
      and direct callers to use `line` instead. Treat `position` as a fallback only; do not use it for new code.

Drafting and submission steps:

1. Build one review payload with every finding embedded in the `comments` array.
2. Position each `comments[]` entry with `line` + `side`. Use `RIGHT` for findings on additions or unchanged
   context lines and `LEFT` for findings on deletions. For multi-line comments, set `start_line` + `start_side`
   together in addition to `line` + `side`. Reach for `position` only as a fallback when `line` cannot target
   the intended location; to compute `position`, use this command template — replace `<PR>` with the PR number
   or URL and `<unique text>` with exact changed-line text:
   ```bash
   gh pr diff "<PR>" --patch | grep -n "<unique text>"
   ```
   Use the returned line number as the `position` parameter.
3. Every inline comment in the `comments` array MUST include a code suggestion when a fix is possible. Use
   GitHub's suggestion block format inside the comment `body`:
   ```suggestion
   // corrected code here
   ```
   This allows the author to apply the fix with one click. Only omit suggestions for observations that have no
   concrete fix (e.g., questions, design discussions, or findings that require broader refactoring).
4. Preserve Markdown newlines exactly when constructing the API payload. Do not encode newlines manually as literal
   `\n` text inside shell strings. Build the body from a real multiline source, such as a temporary Markdown file read
   with `jq --rawfile`, or another method that proves the JSON string contains actual newline characters.
5. Set `body` on the review object to the summary, which must:
    - List what was verified (claims tested, tests run, code paths checked).
    - Briefly reference the inline findings included in this review (do not repeat full details).
    - State the overall verdict and reasoning.
6. Set `event` to `APPROVE`, `REQUEST_CHANGES`, or `COMMENT` based on the approved verdict.
7. Submit the review with one API call. Example template; replace `<owner>`, `<repo>`, `<pull_number>`, and the
   payload contents:
   ```bash
   gh api -X POST "/repos/<owner>/<repo>/pulls/<pull_number>/reviews" \
     --input - <<'JSON'
   {
     "body": "<summary>",
     "event": "<APPROVE|REQUEST_CHANGES|COMMENT>",
     "comments": [
       { "path": "<file>", "line": <n>, "side": "RIGHT", "body": "<inline body with optional suggestion block>" }
     ]
   }
   JSON
   ```
8. After posting or editing GitHub-visible Markdown, fetch the created or edited review/comment body and verify it
   renders from real Markdown line breaks. Check that the stored body does not contain literal `\n` sequences unless
   they are intentionally part of code text. If formatting is wrong, draft the exact correction, get approval for the
   edit, and patch the comment.
9. Never post only a summary review without inline comments when there are specific code-level findings.
10. If the review requires a reply to an existing comment thread rather than a new top-level finding, that reply
   is governed by the `## GitHub write actions: draft-first gate` section above and is a separate posting step.
