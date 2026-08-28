---
name: install-agent-context
description: >-
  Install managed agent instruction files (GLOBAL.md, CLAUDE.md, .claude/context/,
  .claude/skills/, .claude/styles/) from the canonical source to per-agent
  targets (Claude, Codex, Copilot CLI, Cursor). Invoke ONLY when the user runs
  `/install-agent-context` or explicitly asks to install agent context. Do not
  invoke automatically on observed staleness — the user drives this.
---

# Install Agent Context Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Install managed agent instruction files from the canonical source to per-agent targets.

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
- Cursor: `.cursor/rules/global/*.mdc` (per-repo, one file per `GLOBAL.md` section, alwaysApply — see
  "Cursor global rule as project rule" below) | `AGENTS.md` | `.agents/context/AGENTS.md` |
  `.agents/skills/**` | `.agents/styles/**`

For Codex, Copilot CLI, and Cursor, `.agents/context/`, `.agents/skills/`, and `.agents/styles/` are managed
project-local support docs. The root `AGENTS.md` must route agents to these support docs.

Cursor consumes the exact same repo-local layout Codex produces. Cursor reads `AGENTS.md` at the repo root and
in nested subdirectories natively, and discovers skills under `.agents/skills/**/SKILL.md` natively (per
Cursor rules and skills docs).

## Process

1. Ask the user for the canonical source (path, repo, branch, tag, or archive) before copying. Do not infer it.
2. Prefer the helper script when present in the canonical source. Run with `--dry-run` first if target state is
   unclear.
   Command template; replace `<source>` with the canonical source path and `<repo-root>` with the target repository
   root. Use one agent value: `claude`, `codex`, `copilot`, or `cursor`.
   ```bash
   <source>/scripts/install-agent-context.sh --source <source> --agent <claude|codex|copilot|cursor> --target <repo-root>
   ```
3. Copy and migrate only managed files. Preserve relative subdirectories. Migration map:
    - `GLOBAL.md` → the agent's global target (see list above). Cursor has no supported way to create a
      global (User Rule) programmatically or from a file — Cursor's official rule-creation docs at
      <https://cursor.com/docs/rules#creating-a-rule> list exactly two methods (`/create-rule` in chat
      and Customize > Rules > Add Rule), both of which produce Project Rules. For `--agent cursor`,
      after the script finishes, invoke the `create-rule` skill (Cursor's built-in skill for creating
      Project Rules) to split `GLOBAL.md` into one Project Rule per top-level `#` section under
      `<repo>/.cursor/rules/global/`, each with `alwaysApply: true`. See "Cursor global rule as project
      rule" below. Do not create User Rules via MCP tools or scripts — those do not surface in
      Customize > Rules and are not the documented method.
    - `CLAUDE.md` → the agent's repo root (see list above). The root file is written INSIDE a fenced region
      so team-owned content in the same file is preserved. See "Fenced root file" below.
    - `.claude/context/`, `.claude/skills/`, `.claude/styles/` → keep as-is for Claude; rename `.claude/` →
      `.agents/` for Codex, Copilot CLI, and Cursor.
4. Create directories only for managed copies. Do not delete, move, rename, or overwrite unrelated files.
5. Update references when names change. The script's reference transform rewrites `.claude/` → `.agents/`
   and `CLAUDE.md` → `AGENTS.md` inside copied files for non-Claude targets.
6. Keep repo-local root instruction files focused on repo-local concerns (context routing, style routing, dependency
   policy, commit conventions, review). Do not duplicate global behavior or tone sections.
7. After sync, follow the repo-local root file for context and style routing.
8. Report which managed files were created, replaced, skipped as current, prepended, or migrated.

## Fenced root file

The repo root instruction file (`CLAUDE.md` for `--agent claude`, `AGENTS.md` for `--agent codex|copilot|cursor`)
is written inside an HTML-comment fence so team-owned content already in that file is preserved:

```markdown
<!-- BEGIN install-agent-context canonical (do not edit; regenerated by /install-agent-context) -->
<canonical content from the source repo's CLAUDE.md>
<!-- END install-agent-context canonical -->

<team-owned content, if any, lives here and is never touched by the sync>
```

Behavior by target state:

- Target absent → `CREATE` with just the fenced block.
- Target present WITH fence markers → `REPLACE fenced-region in` — awk replaces only the region between the
  BEGIN and END markers. Content outside the fence is preserved byte-for-byte.
- Target present WITHOUT fence markers → `PREPEND fenced-block to` — the fenced canonical block is inserted
  at the top of the existing file, followed by a blank separator line, then the original content unchanged.
- Fresh re-run with no source change → `SKIP fenced-current`.

Never edit content between the fence markers by hand. Anything that must survive the sync goes below (or
above) the fence.

## Cursor global rule as project rule

Cursor documents exactly two rule-creation methods
(<https://cursor.com/docs/rules#creating-a-rule>): `/create-rule` in chat and Customize > Rules > Add
Rule. Both create Project Rules under `.cursor/rules/*.mdc`. There is no documented programmatic way
to create a User Rule (Customize > Rules > User Rules). Attempting to create one via MCP tools like
`cursor-app-control.cursor_dialog` produces a "rule" that does not appear in the Settings UI and cannot
be trusted to load into Agent context — verified in-session by adding, listing (visible only to the
same MCP tool), and observing absence from Customize > Rules. Do not use that path.

Trade-off accepted: `GLOBAL.md` is applied per repo via Project Rules, not globally. Every repo needs
its own copy, and every edit to `GLOBAL.md` requires re-syncing into every repo. Cursor precedence per
docs: Team Rules > Project Rules > User Rules; the per-repo Project Rules created below win over a
conflicting User Rule.

Why split by section: Cursor's `create-rule` skill (installed at
`~/.cursor/skills-cursor/create-rule/SKILL.md` on each operator's machine) recommends keeping rules
"under 50 lines" and "one concern per rule". `GLOBAL.md` today spans multiple concerns (core behavior,
tone, engineering standards, terminal logging, local-only paths, instruction dedup). Copying it as one
file violates that guidance. The split-by-section procedure below matches the skill and keeps each
Project Rule focused.

Procedure for `--agent cursor` (run this as an explicit follow-up after
`install-agent-context.sh --agent cursor` finishes):

1. Invoke the `create-rule` skill's intent by running the helper script
   `scripts/split_global_to_rules.py` from the canonical source:

   ```bash
   python3 <source>/scripts/split_global_to_rules.py \
       --source <source>/GLOBAL.md --target <repo-root>
   ```

   The script parses `GLOBAL.md` into sections at each top-level `#` heading, slugs each heading, and
   writes `<repo>/.cursor/rules/global/<slug>.mdc` with `alwaysApply: true`. By default it skips the
   `# Context` section (skill-preamble, not runtime guidance); override with `--skip-heading <name>`
   (repeatable) or pass a single dummy value to disable the default skip.
2. Confirm the output. Expected messages: `CREATE` / `REPLACE` / `SKIP  current` / `SKIP  heading`,
   and `DELETE` for any `.mdc` under `global/` whose owning section no longer exists in `GLOBAL.md`.
3. Do not edit the bodies by hand. Anything the repo needs to override or extend belongs in a
   separate `.cursor/rules/*.mdc` file outside `global/` — the `global/` files are regenerated from
   `GLOBAL.md`.
4. Commit `.cursor/rules/global/` per Cursor docs guidance ("Check your rules into git so your whole
   team benefits").
5. Report each CREATE/REPLACE/SKIP/DELETE path alongside the other sync results.

Idempotence is enforced by the script: identical files are skipped; changed files are replaced;
orphan files (whose owning section was removed from `GLOBAL.md`) are deleted. Do not touch any other
file under `.cursor/rules/`.

Alternative if you prefer the fully interactive path:

- Open the target repo in Cursor, run `/create-rule` in chat once per section, and paste the section
  contents. This is one of the two official methods and produces the same files. It is slower but
  keeps the agent inside the documented UI flow.

Notes:

- User Rules (Customize > Rules > User Rules) remain useful if the user wants to paste `GLOBAL.md` in
  manually through the UI. That path is officially supported for existing rules but not documented as
  a creation entry point. This skill does not automate it and does not require it.
- The helper script `scripts/install-agent-context.sh` does not write `.cursor/rules/global/*.mdc` today.
  The companion script `scripts/split_global_to_rules.py` handles that step; run it as an explicit
  follow-up after `install-agent-context.sh --agent cursor` as shown in the procedure above.

## Gitignore for sync-owned files

After a successful sync, the helper script writes a fenced block into
`<target>/.gitignore` listing the paths install-agent-context creates or modifies:

```
# BEGIN install-agent-context (do not edit; regenerated by /install-agent-context)
AGENTS.md
CLAUDE.md
.agents/**
.claude/**
.cursor/**
# END install-agent-context
```

Behavior by target state (mirrors the CLAUDE.md fence logic):

- `.gitignore` absent → `CREATE` with just the fenced block.
- `.gitignore` present with fence markers → `REPLACE gitignore-region in`. Everything outside the fence
  is preserved byte-for-byte.
- `.gitignore` present without fence markers → `APPEND gitignore-block to`. A blank separator is
  inserted first, then the fenced block.
- Fresh re-run with no source change → `SKIP gitignore-current`.

Trade-off named explicitly: Cursor's docs
(<https://cursor.com/docs/rules#project-rules>) tell teams to check `.cursor/rules/` into git so the
whole team benefits, and the AGENTS.md standard is designed for shared team-visible instructions. This
skill deliberately ignores those paths because the operator's rules, skills, and project rules are
private prompt engineering rather than team infrastructure. Teams that want shared agent guidance
should either (a) delete or narrow the entries between the fence markers after the sync, or (b) not
run this skill against a team repo. The fence structure supports both — hand edits outside the fence
survive re-syncs, and edits inside the fence are overwritten.

Do not edit content between the `# BEGIN install-agent-context` and `# END install-agent-context` markers
by hand. Anything that must survive re-sync goes above or below the fence.

## GitHub Copilot code review

GitHub Copilot also supports `.github/copilot-instructions.md` and `.github/instructions/**/*.instructions.md`
for GitHub.com and code-review surfaces. Those are not managed by this sync unless the user explicitly asks
for that compatibility.
