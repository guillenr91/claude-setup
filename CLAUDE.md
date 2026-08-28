# Project Instructions

Loaded into context. Keep concise, explicit, and actionable for AI agents. No decorative formatting around prose
(no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

## Context routing

When the task could touch project-specific context — building, running, debugging, editing repo code, env vars,
deployment, integrations, schemas, or any answer that depends on what is in this repo — read
[.claude/context/CLAUDE.md](.claude/context/CLAUDE.md) before acting and use it to choose which project context
files to load. For purely conversational, meta, or instruction-file turns that do not touch project code, you may
skip it.

Keep this file portable: route only to `SETUP.md` and `TECHNICAL.md`. Project-specific runbooks (env, deployment, etc.)
should be referenced from `SETUP.md` or `TECHNICAL.md` instead.

### Where information goes

Each directory under `.claude/` owns its own rules in its own `CLAUDE.md`. Before writing anything durable, read
the `CLAUDE.md` of the directory you are targeting:

- Project-agnostic style and convention rules → [.claude/styles/CLAUDE.md](.claude/styles/CLAUDE.md).
- Project-wide reference (`SETUP.md`, `TECHNICAL.md`) and ticket-scoped files (`tickets/<TICKET_ID>/`) →
  [.claude/context/CLAUDE.md](.claude/context/CLAUDE.md).

Do not duplicate facts across directories; cross-link instead. When unsure where something belongs, ask before
writing.

## Style guides

Before creating or modifying style guides, read [.claude/styles/CLAUDE.md](.claude/styles/CLAUDE.md).

Before generating or reviewing work in a domain covered by `.claude/styles/`, read the matching style guide first:

- Java code → [JAVA.md](.claude/styles/JAVA.md)
- Postman collections, requests, environments, scripts → [POSTMAN.md](.claude/styles/POSTMAN.md)
- Workflow diagrams, architecture diagrams, any visual documentation →
  [DIAGRAMS.md](.claude/styles/DIAGRAMS.md)
- Markdown files that contain commands, setup steps, or procedures →
  [MARKDOWN.md](.claude/styles/MARKDOWN.md)
- Any other domain with a Markdown file in `.claude/styles/` → that file.

## Answering with evidence

Before sending any reply that makes a factual claim — about code, tools, docs, external systems, or prior
conversation state — invoke the `evidence-first` skill. It applies to every reply, including short and
conversational ones. Skip only for pure meta replies with no factual content, pure opinion clearly labeled as
such, recaps of what the operator just said, and read-only lookups whose output is shown in the same turn.

## Dependency changes

Before editing dependency manifests, installing CLI tools, or adding OS packages, invoke the `add-dependency`
skill.

## Commits, PRs, and reviews

Before running `git commit` or `git push`, or drafting a commit message, invoke the `commit-review` skill.

Before running `gh pr create`, `gh pr edit`, submitting a PR review, posting inline review comments or replies,
creating or commenting on issues, or drafting a PR description / PR review / PR reply, invoke the
`manage-pull-request` skill.

Any code review — pre-commit, pre-PR, reviewing someone else's PR, or ad-hoc analysis — invokes the
`code-review-effort` skill. `commit-review` and `manage-pull-request` invoke it as part of their pre-commit and
pre-PR review steps; invoke it directly when the user asks for a code review outside those triggers.

## Agent context sync

Invoke the `install-agent-context` skill when the user runs `/install-agent-context` or explicitly asks to sync agent
instruction files across agents (Claude, Codex, Copilot CLI). Do not sync automatically.