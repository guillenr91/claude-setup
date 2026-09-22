---
name: reload-agent-context
description: >-
  Re-read agent context files from disk only when the operator explicitly
  invokes /reload-agent-context or explicitly asks to reload agent context.
  Never invoke automatically after file edits, scripts, sub-agent work, Git
  operations, context installation, or before applying changed context rules.
---

# Reload Agent Context Skill

Loaded into context when invoked. Keep brief and concise, explicit, and actionable for AI agents. Preserve every concrete instruction and action; cut verbose prose. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Re-reads agent context from disk only when the operator explicitly requests it. It is never an automatic freshness check.

## What counts as agent context

Any file whose contents define agent behavior, project rules, style, workflow, or context. Agent-agnostic list — each entry covers the equivalent path under whichever agent format is in use:

- Root instruction files: `CLAUDE.md`, `AGENTS.md`, and any equivalent root-level agent instruction file (e.g. `.codex.md`, `copilot-instructions.md`).
- Every `CLAUDE.md` under `.claude/` and every `AGENTS.md` under `.agents/`.
- Every `SKILL.md` under `.claude/skills/*/` or `.agents/skills/*/`.
- Every file under `.claude/styles/` or `.agents/styles/`.
- Every file under `.claude/context/` or `.agents/context/` — including project-wide reference (`SETUP.md`, `TECHNICAL.md`) and ticket-scoped subtrees (`tickets/<TICKET_ID>/**`).
- Cursor project rules: `.cursor/rules/**/*.mdc`.
- Harness settings that affect agent behavior: `.claude/settings.json`, `.claude/settings.local.json`, and per-agent equivalents.
- Global instruction files the current agent loads at startup: `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.copilot/copilot-instructions.md`, and equivalents.

If unsure, treat as agent context and reload.

## Trigger

Invoke this skill only when the operator runs `/reload-agent-context` or explicitly asks to reload agent context or a named context file. Do not invoke for automatic freshness checks, including after edits, scripts, sub-agent work, Git operations, context installation, or changed context rules.

## Reload procedure

1. Identify the files the operator asked to reload. For `/reload-agent-context` without named files, identify every agent context file modified since the current turn began.
2. Re-read each selected file end-to-end. Do not read only changed hunks; a rule may reference another section.
3. If a selected directory-level instruction file (`CLAUDE.md` / `AGENTS.md`) routes to child files, re-read the routed child files.
4. If a selected `SKILL.md` is currently loaded, treat the newly read content as authoritative.
5. Re-check any in-flight decision that used a reloaded rule. If it changes the decision, state the impact and adjust.

## Reporting

After a reload, state which files were re-read and whether any rule changed the plan. One line per file is enough when nothing material changed. Example:

- `CLAUDE.md` / `AGENTS.md`: re-read, no rule affecting current work changed.
- `.claude/skills/commit-review/SKILL.md` (or `.agents/skills/commit-review/SKILL.md`): re-read, added commit-message approval gate — commit flow adjusted.

## Anti-patterns

- Invoking after an edit, script, sub-agent change, Git operation, context installation, or rule change without an explicit operator request.
- Treating this skill as a routine context-freshness check.
- Reading only changed hunks when the operator asked to reload a file.
- Re-reading a parent instruction file without its routed child files when the parent is in scope.
