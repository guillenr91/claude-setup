---
name: reload-agent-context
description: >-
  Re-read agent context files from disk after any modification so decisions
  are not made against a stale in-context representation. Invoke immediately
  after you or any other tool, sub-agent, script, or workflow modifies an
  agent context file (root CLAUDE.md / AGENTS.md, every CLAUDE.md / AGENTS.md
  under .claude/ or .agents/, every SKILL.md under .claude/skills/ or
  .agents/skills/, files under .claude/styles/ or .agents/styles/, files
  under .claude/context/ or .agents/context/, .cursor/rules/**, and any
  per-agent instruction file the operator uses). Also invoke after operations
  that can rewrite context files (git checkout / pull / rebase / merge / stash
  pop, patch apply, install-agent-context runs, sub-agent or workflow
  completions that reported writes), when the operator asks to reload context
  or names a context file to re-read, and before applying rules from a
  context file that has been modified in-session but not re-read since the
  modification. Do not invoke for read-only operations on these files, or for
  changes to non-context files.
---

# Reload Agent Context Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Ensures agent context is re-read from disk after any modification so subsequent decisions run against the current
file, not an older version cached in prior turns or in the initial system prompt.

## What counts as agent context

Any file whose contents define agent behavior, project rules, style, workflow, or context. Agent-agnostic list —
each entry covers the equivalent path under whichever agent format is in use:

- Root instruction files: `CLAUDE.md`, `AGENTS.md`, and any equivalent root-level agent instruction file the
  operator's setup uses (e.g. `.codex.md`, `copilot-instructions.md`).
- Every `CLAUDE.md` under `.claude/` and every `AGENTS.md` under `.agents/`.
- Every `SKILL.md` under `.claude/skills/*/` or `.agents/skills/*/`.
- Every file under `.claude/styles/` or `.agents/styles/`.
- Every file under `.claude/context/` or `.agents/context/` — including project-wide reference
  (`SETUP.md`, `TECHNICAL.md`) and ticket-scoped subtrees (`tickets/<TICKET_ID>/**`).
- Cursor project rules: `.cursor/rules/**/*.mdc`.
- Harness settings that affect agent behavior: `.claude/settings.json`, `.claude/settings.local.json`, and
  per-agent equivalents.
- Global instruction files the current agent loads at startup: `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`,
  `~/.copilot/copilot-instructions.md`, and equivalents.

If unsure whether a file is agent context, treat it as agent context and reload.

## Triggers

Reload immediately after any of:

1. You (this agent) edited or wrote to a file listed above. The harness's "file state is current in your context"
   confirmation covers the tracked file state, not your working understanding — the initial system prompt and
   earlier turns still hold the older content. Re-read to bring the current content forward.
2. Another tool, sub-agent, workflow, or script modified one of those files. This includes install-agent-context
   runs, publish/deploy scripts, external editors, and sub-agent completions that reported writes.
3. The operator ran a command that can rewrite context files: `git checkout`, `git pull`, `git rebase`,
   `git merge`, `git stash pop`, `git reset --hard`, `git apply` / `patch`, or an in-place formatter run.
4. The operator asks to reload context, or names a specific context file to re-read.
5. Before applying rules from a context file that has been changed in-session but not re-read since the change.

Do not skip because the edit "seemed small" or because you can "remember what changed". The stale representation
is what caused the problem.

## Reload procedure

1. Identify every context file that has been modified since it was last read into your context. Include files
   you edited yourself — track state and working understanding are not the same thing.
2. Re-read each changed file end-to-end. Do not read only the changed hunks — the file's rules may reference
   sections outside your edit.
3. If a directory-level instruction file (`CLAUDE.md` / `AGENTS.md`) was modified, re-read it AND every child
   instruction file whose loading it routes to.
4. If a `SKILL.md` was modified for a skill that is currently loaded in the turn, treat the freshly-read content
   as authoritative and discard any prior in-context representation of that skill.
5. After reload, re-verify any in-flight decision that used rules from the reloaded file. If a rule changed in a
   way that would have altered a prior decision this turn, name the affected decision to the operator and adjust.

## Reporting

After a reload, state which files were re-read and whether any rule changed the plan. Keep it short — one line
per file is enough when nothing material changed. Example:

- `CLAUDE.md` / `AGENTS.md`: re-read, no rule affecting current work changed.
- `.claude/skills/commit-review/SKILL.md` (or `.agents/skills/commit-review/SKILL.md`): re-read, added
  commit-message approval gate — commit flow adjusted.

## Anti-patterns

- "I just edited it, I know what it says" — the just-edited representation drifts as later turns compress or
  paraphrase. Re-read.
- "It was only a typo fix, no need to reload" — you cannot verify the surrounding text is unchanged without
  reading it.
- "I'll reload it later when I need it" — later is when the stale rule has already been applied. Reload now.
- "The write tool's confirmation said file state is current" — that guarantees the tracked file state, not a
  refreshed working understanding. Re-read to bring the current content forward in context.
- "The operator's IDE just saved something, I saw the notification" — the notification is not a read.
- "The sub-agent's final message says it edited the file" — trust and verify. Re-read the file.
- "I re-read the parent `CLAUDE.md` / `AGENTS.md` but not the child files it routes to" — routing changes are
  load-bearing. Re-read the tree.
