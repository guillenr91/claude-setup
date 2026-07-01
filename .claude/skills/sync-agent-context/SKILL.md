---
name: sync-agent-context
description: >-
  Sync managed agent instruction files (GLOBAL.md, CLAUDE.md, .claude/context/,
  .claude/skills/, .claude/styles/) from the canonical source to per-agent
  targets (Claude, Codex, Copilot CLI). Invoke ONLY when the user runs
  `/sync-agent-context` or explicitly asks to sync agent context. Do not
  invoke automatically on observed staleness — the user drives this.
---

# Sync Agent Context Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Sync managed agent instruction files from the canonical source to per-agent targets.

## Scope

Managed source files (canonical source only): `GLOBAL.md`, `CLAUDE.md`, `.claude/context/CLAUDE.md`,
`.claude/skills/**`, `.claude/styles/**`.

Managed targets per agent — each line lists: global instructions | repo root | repo context | repo skills |
repo styles.

- Claude: `~/.claude/CLAUDE.md` | `CLAUDE.md` | `.claude/context/CLAUDE.md` | `.claude/skills/**` |
  `.claude/styles/**`
- Codex: `~/.codex/AGENTS.md` | `AGENTS.md` | `.agents/context/AGENTS.md` | `.agents/skills/**` |
  `.agents/styles/**`
- Copilot CLI: `$HOME/.copilot/copilot-instructions.md` | `AGENTS.md` | `.agents/context/AGENTS.md` |
  `.agents/skills/**` | `.agents/styles/**`

For Codex and Copilot CLI, `.agents/context/`, `.agents/skills/`, and `.agents/styles/` are managed project-local
support docs. The root `AGENTS.md` must route agents to these support docs.

## Process

1. Ask the user for the canonical source (path, repo, branch, tag, or archive) before copying. Do not infer it.
2. Prefer the helper script when present in the canonical source. Run with `--dry-run` first if target state is
   unclear.
   Command template; replace `<source>` with the canonical source path and `<repo-root>` with the target repository
   root. Use one agent value: `claude`, `codex`, or `copilot`.
   ```bash
   <source>/scripts/sync-agent-context.sh --source <source> --agent <claude|codex|copilot> --target <repo-root>
   ```
3. Copy and migrate only managed files. Preserve relative subdirectories. Migration map:
    - `GLOBAL.md` → the agent's global target (see list above).
    - `CLAUDE.md` → the agent's repo root (see list above).
    - `.claude/context/`, `.claude/skills/`, `.claude/styles/` → keep as-is for Claude; rename `.claude/` →
      `.agents/` for Codex and Copilot CLI.
4. Create directories only for managed copies. Do not delete, move, rename, or overwrite unrelated files.
5. Update references when names change.
6. Keep repo-local root instruction files focused on repo-local concerns (context routing, style routing, dependency
   policy, commit conventions, review). Do not duplicate global behavior or tone sections.
7. After sync, follow the repo-local root file for context and style routing.
8. Report which managed files were created, replaced, skipped as current, or migrated.

GitHub Copilot also supports `.github/copilot-instructions.md` and `.github/instructions/**/*.instructions.md` for
GitHub.com and code-review surfaces. Those are not managed by this sync unless the user explicitly asks for that
compatibility.
