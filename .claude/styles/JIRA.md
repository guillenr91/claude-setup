# Jira Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Read before creating or editing Jira issue descriptions, Jira comments (new or updated), or drafts intended to be
posted to Jira via API or MCP tools. Applies to Jira Cloud (`*.atlassian.net`).

### Rule: Use the Atlassian MCP plugin for every Jira read and write

Trigger: reading an issue, creating an issue, posting a comment, editing a comment, or transitioning an issue.
Do: use the Atlassian MCP plugin.
Do: when the plugin is not installed, stop and ask the user to install it. Do not fall back to another tool.
Do: when the plugin is installed but not authenticated, stop and ask the user to authenticate, then retry.
Do not: use a general-purpose assistant or other MCP server that exposes Jira write helpers as a convenience. Those
tools reformat submitted markup on the way through and append an attribution footer per call.
Exception: read-only issue fetches through another tool are acceptable when the Atlassian plugin is unavailable and the
content is only being summarized, never written back.

### Rule: Match the markup to the write path's content format

Trigger: writing any text that will be posted to a Jira Cloud comment or issue field.

Do: check whether the write tool takes a content-format parameter, and match the markup to it. There are three paths
and they are not interchangeable:

- Tool declares `contentFormat: markdown` — write Markdown. Suitable for ordinary comments: headings, bullets, inline
  code, fenced code blocks, links, bold.
- Tool declares `contentFormat: adf` — write Atlassian Document Format JSON. Use when the comment needs fidelity
  Markdown cannot express, such as panels, statuses, expand blocks, or a code block whose language must be set.
- Tool takes a raw body string with no content-format parameter — write Jira wiki markup, using the token map below.
  This is the legacy REST v2 path.

Do: state the chosen format when handing a draft to a human, so the next agent does not send it through the wrong path.

Do not: mix two of the three in one body. Markdown syntax on the wiki-markup path renders as a wall of raw symbols, and
wiki-markup tokens on the Markdown path render as literal `h2.` and `{{…}}` text.

Exception: if a human will paste the text into the Jira web editor manually, Markdown is fine regardless of path — the
web editor converts paste-time Markdown locally. Label the draft as "for manual paste".

### Rule: Map every formatting need to a wiki-markup token

Trigger: writing a body for the raw-body path described above, where no content format can be declared.

Do: use the exact wiki-markup tokens below. These are the tokens that render correctly through the ADF conversion the
legacy API applies.

- Heading level 2: `h2. <text>` on its own line, followed by a blank line.
- Heading level 3: `h3. <text>` on its own line, followed by a blank line.
- Inline monospace / inline code: `{{<text>}}`. Use for identifiers, field names, endpoints, HTTP headers,
  file paths, values, IDs, commit SHAs.
- Preformatted block (no syntax highlighting, preserves whitespace): open with `{noformat}` on its own line, close
  with `{noformat}` on its own line. Content goes between. Use for shell commands, curl invocations, multi-line
  request/response payloads when a language tag is not needed.
- Code block with language: `{code:<lang>}` … `{code}` (e.g. `{code:java}`, `{code:json}`, `{code:bash}`).
- Bulleted list: `* <item>` (one item per line, no blank line between items in the same list).
- Numbered list: `# <item>`.
- Bold: `*<text>*`. Do not use for whole paragraphs; reserve for short emphasis inside a line.
- Italic: `_<text>_`.
- Link with label: `[<label>|<url>]`.
- Bare link: `<url>` on its own or inline. Jira will auto-link.
- Table row: `| cell | cell |`; header row uses `|| header || header ||`.
- Horizontal rule: `----` on its own line.

Do not: mix Markdown and wiki markup in the same block. Do not wrap code in single backticks — write `{{value}}`.
Do not wrap code in triple-backtick fences — write `{noformat}` … `{noformat}`.

### Rule: Verify the stored body after any API post or edit

Trigger: after any comment or issue-field write.
Do: re-read the stored body and confirm:

- The markup rendered as structure, not as literal tokens. No leading backslashes, no literal `\{code}` or `\*`, no
  visible `h2.` or `##`.
- Section headings render as headings.
- Code blocks contain the intended lines with preserved newlines.

Do: if any token was escaped or mangled, fix it in a follow-up edit before ending the turn. Do not leave a broken
render in the ticket.

### Rule: Keep comments scoped to what the audience can act on

Trigger: writing a QE handoff, PR-status update, or any comment aimed at another team member.

Do not: reference files, paths, or artifacts that only the author can access (local repo paths, private branches,
personal machine paths). If a spec or design doc lives only locally, either publish it first (Confluence, shared
drive) and link the published version, or omit the reference.

Do: link Jira keys, PR URLs, published Confluence pages, and shared tickets by full URL or key. Prefer
`[<label>|<url>]` over bare URLs when the label adds meaning.

### Rule: Use the project's QE handoff template when one exists

Trigger: writing the first "ready for QA" comment on a ticket in a project that documents a handoff template.

Do: follow the project's template section-for-section. If the template lives in project context
(`.agents/context/` or a linked runbook), read it and reproduce the required sections in wiki markup. Include:

- A short description of what changed and why.
- Risk assessment.
- Test coverage summary (unit / integration / manual).
- Recommendations to QE (segments, edge cases, reproduction hints).
- Components affected.
- Manual verification results, kept in its own section with expected vs. actual per usecase.

Do not: invent template sections that are not in the project's documented template. If the project has no
template, ask before improvising.

### Rule: Prefer editing one canonical comment over stacking new comments

Trigger: iterating on a status update, QE handoff, or progress note on the same ticket.

Do: update the existing comment in place when the content is the canonical version of that information. Preserves a
single source of truth per ticket and avoids scroll-fatigue for reviewers.

Do not: post a new comment for every small revision. New comments are appropriate for distinct events (PR merged,
deploy started, QA blocker found), not for typo fixes or formatting corrections.

### Rule: Never restate the requester in the comment body

Trigger: posting a comment through any tool that appends an attribution footer.

Do not: repeat "Requested by …" or "Posting on behalf of …" in the comment body. The tool footer already
identifies the requester; duplicating it clutters the comment.
