---
name: manage-pull-request
description: >-
  Pull request creation, editing, review submission, inline comments and
  replies, addressing incoming PR feedback, and issue creation/comments on
  GitHub. Invoke before running `gh pr create`, `gh pr edit`, submitting a PR
  review, posting inline review comments or replies, or creating or commenting
  on issues. Also invoke when the user asks to draft a PR description, PR
  review, PR reply, or to address feedback on a PR. Do not invoke for local
  commits or `git push` — those are covered by commit-review.
---

# Manage Pull Request Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Applies pre-PR review, GitHub write-action draft-first gate, addressing incoming PR feedback, and PR review
authoring rules.

## Pre-PR review

Triggers immediately before running `gh pr create`. Also triggers before `gh pr edit` when the edit changes the PR's
scope or claims (title, description body, base branch). Skip for pure typo fixes to an existing description.

Invoke the `code-review-effort` skill and apply its rules to the changes in the PR — every time, even when the
change feels small. Use the review output to write the PR description's summary of what was verified.

## Draft-first gate for GitHub write actions

Applies to every action that creates or modifies content visible on GitHub: opening a PR (`gh pr create`), editing
a PR title or description (`gh pr edit`), submitting a PR review or any inline review comment (`gh api` POSTs to
`pulls/.../reviews` or `pulls/.../comments`), replying to existing PR review comments (top-level or threaded), and
creating or commenting on issues. Local commits and `git push` are governed by the commit-review skill, not this
gate.

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

## Addressing incoming PR feedback

Triggers when someone leaves a comment, review, or requested change on a PR the operator owns and the operator asks
to address it. This is distinct from `## PR review feedback` below, which covers reviews the operator is authoring.

Follow this sequence in order. Do not merge or reorder steps. Do not skip because a step looks small.

1. Analyze the incoming comment against the affected code. State plainly whether the comment is right, partially
   right, or wrong, and what the resulting change (if any) is.
2. Apply the change locally. Do not commit yet.
3. Run the fully impacted test suite for the changed file(s) end-to-end (not `--dryrun` alone) and confirm it
   passes. If local live runs are not available for the project, run the closest verification the project supports
   and say so. Do not skip verification just because the diff looks small.
4. Show the operator the diff and the test result. Wait for the operator to approve committing.
5. Commit locally by invoking the `commit-review` skill (it enforces commit conventions, pre-commit review, and the
   commit-message approval gate). Do not push. Do not mention reviewers, authors, or any human names in the commit
   message.
6. Wait for the operator to review the local commit and push it themselves. Do not push on their behalf unless
   they explicitly ask you to.
7. Verify the push landed before drafting any reply. Confirm the commit SHA exists on the remote branch
   (`git ls-remote origin <branch>` or `gh pr view <n> --json headRefOid`) and matches the local commit. Do not
   draft or post a reply that cites a SHA that is not yet on the remote.
8. Only after the push is verified, draft each PR reply in chat. Keep replies brief and concise: acknowledge the
   point, state the fix in one or two sentences, cite the pushed SHA. Do not restate the full analysis.
9. Get explicit operator approval for each reply. Approval of one reply does not extend to others.
10. Only after approval, post the replies using the draft-first gate above.

Never post a reply, comment, or review to GitHub until steps 1–9 are complete and the operator has approved the
exact text of each reply.

## PR review feedback

The goal of every review comment is to help the developer improve their code or solve a detected issue. Comments that
only point out problems without providing a path forward are not useful. Every comment should enable the developer to
take immediate action.

Invoke the `code-review-effort` skill before posting any feedback: discover the review capabilities available in the
current environment, use every applicable capability, and use the highest effort level the task warrants. Findings
posted as PR comments must come from that pass, not from a glance at the diff.

When reviewing a PR:

- Verdict selection is mechanical, not stylistic. After the `code-review-effort` pass, classify every surviving
  (evidence-first-verified) finding as blocking or non-blocking, then apply the table below. Do not default to
  `COMMENT` to hedge — an unverified concern is not a blocker, and a non-blocking observation does not downgrade
  approval.

  | Verified blockers? | Non-blocking findings? | Verdict         |
  |--------------------|------------------------|-----------------|
  | Yes (≥1)           | any                    | REQUEST_CHANGES |
  | No                 | Yes                    | APPROVE         |
  | No                 | No                     | APPROVE         |

  A blocker is a VERIFIED (evidence-first-passed) finding that causes clear breakage, security risk, data loss, or
  behavior likely to harm a supported workflow — see the `[BUG]` vs `[POSSIBLE ISSUE]` rules below. Edge cases,
  hardening, polish, doc gaps, and low-risk maintainability are non-blocking unless evidence shows they break a
  supported workflow. Reserve `COMMENT` for genuinely-ambiguous cases where the operator explicitly declined to
  pick a side; state that reason in the summary if you use it.

- Calibrate state to impact. `REQUEST_CHANGES` only for clear breakage, security risk, data loss, or behavior
  likely to harm a workflow. Edge cases, hardening, polish, doc gaps, and low-risk maintainability are non-blocking
  unless evidence shows they break a supported workflow. For additive PRs that don't break existing behavior, state
  the risk plainly and say whether it should block.
- Prefix every comment title with an uppercase category in brackets: `[BUG]`, `[POSSIBLE ISSUE]`, `[SECURITY]`,
  `[PERFORMANCE]`, `[TEST]`, `[DOCS]`, `[MAINTAINABILITY]`. Use `[LEGACY BUG]` for pre-existing issues — note
  them, but they don't block approval unless the PR makes them worse.

  Category selection — pick by the primary axis of concern, not the reviewer's convenience:

  - `[BUG]` / `[POSSIBLE ISSUE]` — correctness. `[BUG]` = verified in-session to break; `[POSSIBLE ISSUE]` =
    plausible defect, unverified.
  - `[SECURITY]` — exploitable weakness (auth, injection, secret exposure, sandbox escape, etc.).
  - `[PERFORMANCE]` — extra CPU, memory, I/O, latency, or cost with no correctness impact. Use for redundant
    reads, duplicate work, missing caches, hot-path allocations. Do NOT use `[MAINTAINABILITY]` for these —
    "duplicate DB read" is a performance concern even when the fix looks like a refactor.
  - `[TEST]` — missing, wrong, or misleading test coverage.
  - `[DOCS]` — javadoc / README / comment inaccuracy or gap.
  - `[MAINTAINABILITY]` — future readability, name/structure clarity, dead code, non-obvious invariants that
    should be commented. Reserve for concerns that only affect readers, not runtime behavior or cost.

- Use `[BUG]` only when the issue has been VERIFIED in-session to block existing or new code (reproduced, traced
  through the code path, or confirmed by test output). If the issue is a plausible defect you have not verified
  blocks a workflow, use `[POSSIBLE ISSUE]` instead — it reflects that the concern is unverified. Do not upgrade
  `[POSSIBLE ISSUE]` to `[BUG]` on suspicion alone. The same verification rule applies to `[PERFORMANCE]`: if the
  regression is measured or traced in-session, state that; if it is a plausible-cost concern without a
  measurement, keep the `[PERFORMANCE]` prefix but frame the body as an unverified concern to be confirmed.
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
  operator, not to yourself. The reviewer agent must be invisible — never let the agent's identity leak (e.g.
  "I (Claude)", "I (Codex)", "I (Cursor)", "the agent", "from my read as an assistant") or anything that breaks
  the operator-as-reviewer voice. Example: "I checked the auth middleware and noticed X — could you verify
  whether…". The drafts shown to the operator for approval use this same voice so the operator can edit before
  posting.
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
- Keep the category prefix (`[BUG]`, `[POSSIBLE ISSUE]`, `[TEST]`, etc.) on inline comments — the prefix signals
  severity AND verification state; the body should still invite verification rather than declare it.
- The category encodes verification. `[BUG]` means verified-blocking; `[POSSIBLE ISSUE]` means unverified. If you
  cannot reproduce or trace the failure in-session, the correct prefix is `[POSSIBLE ISSUE]`, not `[BUG]` softened
  with hedging language.

Posting review comments:

Apply the `## Draft-first gate for GitHub write actions` section above before any API call.

Drafting workflow for review comments:

Hard sequence — do not merge, skip, or reorder these steps. Each is a stop-and-wait gate.

1. GATHER + FALSIFY — collect every candidate finding surfaced by the `code-review-effort` pass, then run its
   Popperian falsification step (skill's Rule 3) on each one BEFORE the triage table exists. For each candidate,
   name the evidence that would prove it wrong, go get that evidence in-session, and drop the finding if the
   evidence falsifies it — or if you cannot obtain the evidence at all. The operator's triage input in step 2 is
   the surviving-after-falsification list only. Do NOT include "I could not verify but wanted to flag" findings —
   go verify first, or drop.

2. TRIAGE TABLE (mandatory, FIRST operator interaction) — the very next thing you show the operator after the
   review pass is the triage table below. It must be the first thing in your message. Do NOT precede it with a
   summary paragraph, capabilities recap, verdict prose, or any other framing content. Skill/tool status
   updates go AFTER the table, not before. If you have nothing else to say, say nothing — the table is
   sufficient by itself.

   Table shape — exactly this Markdown, one row per surviving finding, `#` starts at 1:

   ```markdown
   | # | Comment | Trigger | Impact | Blocking? |
   |---|---------|---------|--------|-----------|
   | 1 | <2–4 word slug> | <concrete condition to hit it> | <what breaks / degrades / mis-attributes> | <Yes/No — one-line reason> |
   ```

   Column discipline (enforce every row):

   - `#` — 1-indexed integer so the operator can say "keep 1 and 3, drop 2".
   - `Comment` — 2–4 words TOTAL, no backticks, no code identifiers. This is a slug the operator scans, not a
     description. If you cannot fit the finding in 4 words, the slug is wrong — pick a different noun phrase.
     Examples of correct slugs: "duplicate subscription read", "wire schema coupling", "dedup key null
     formatting". Examples of WRONG slugs (too long / code-heavy): "Duplicate getUserSubscriptions read on
     post-expiry send path", "`locationId` camelCase vs `plan_code` snake_case".
   - `Trigger` — the concrete condition that produces the issue: specific inputs, state, config, or code path.
     One sentence. No file paths or line numbers in this column (they belong in the inline body later).
   - `Impact` — what actually goes wrong when the trigger fires. Behavior change, wrong data, extra cost,
     silent drop, mis-attributed metric. One sentence, concrete outcome.
   - `Blocking?` — `Yes — <reason>` for verified blockers (per the verdict-selection table above), `No —
     <reason>` for non-blocking. Reason must explain WHY it does or does not block; do not just repeat "No".

   Table rules:

   - Include EVERY finding that survived `evidence-first`, blocking or not. Do not pre-filter to "the ones I
     think you'd keep" — the operator makes that call.
   - Do NOT include the inline-comment body, file paths, line numbers, code suggestions, or verdict rationale
     inside the table. Those come in step 4.
   - Immediately AFTER the table (still in the same message), on one line, state the verdict that follows
     from the `Blocking?` column via the verdict-selection table above (`APPROVE` / `REQUEST_CHANGES`), so the
     operator can override before drafting. One line, no rationale prose.
   - If additional context is required for the operator to decide (e.g. a review capability failed to run),
     add ONE short line after the verdict line naming what was skipped and why. Do not expand into a status
     narrative.

3. WAIT — stop and wait for the operator to select rows. "Keep 1 and 3" / "all of them" / "drop 2 and 5" all
   count. Silence does not. Do not draft bodies preemptively.

4. DRAFT BODIES — for each kept row, and only for those rows, draft the full inline-comment body (title line
   + blank + body, with a `suggestion` block when a concrete fix exists). Show the operator the exact body,
   the file and line it will attach to, and the proposed verdict.

5. EDIT — apply changes the operator requests. If they reject a body after seeing it, drop it; do not post it
   anyway or re-draft a near-duplicate to argue.

6. POST — only after explicit approval on the final drafts AND the verdict, run the posting steps below.

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
   is governed by the `## Draft-first gate for GitHub write actions` section above and is a separate posting step.
