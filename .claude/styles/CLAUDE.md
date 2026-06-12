# Style Guide Instructions

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Read this before creating or modifying any Markdown file in `.claude/styles/`. Every guide in this directory is a
required pre-read before generating or reviewing work in its domain. Name new guides by domain (`JAVA.md`,
`POSTMAN.md`, etc.) so the matching file is obvious.

Scope rule for this directory: PROJECT-AGNOSTIC style and convention rules only. This is a hard boundary, not a
preference. Project-specific facts go in `.claude/context/` instead — see
[.claude/context/CLAUDE.md](../context/CLAUDE.md).

Forbidden in any file under `.claude/styles/`:

- Real module names, class names, helper names, function names from this repo.
- Real file paths or directory names from this repo.
- Real table schemas, column names, field names.
- Real environment URLs, host names, API keys (even placeholder values).
- Real tag values, branch names, ticket IDs, PR numbers.
- Code examples that reference any of the above.

Allowed in style guides:

- Generic placeholders (`<TICKET_ID>`, `<aggregator>`, `<area>`, `<service>`, `<env-or-suite-tags>`).
- Domain-standard concepts (Robot Framework `Suite Setup`, Java `Optional`, HTTP verbs, etc.).
- Code shapes built from placeholders.

Test before committing: clone a different repo using the same domain (a different Java service, a different Robot
suite). Would this rule still apply unchanged? If no → it does not belong here, move it to `.claude/context/`.

## Required header

Every style guide must start with:

```markdown
# <Domain> Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.
```

After the header, add one short sentence explaining when to use the guide.

## Writing rules

- Format each rule as `### Rule: <imperative rule name>`.
- State the trigger before the action.
- Use `Trigger:`, `Do:`, `Do not:`, and `Exception:` as plain colon-prefix labels at the start of a line.
- Include examples only when they disambiguate.
- Prefer existing project patterns when they conflict with a general rule.
- Remove stale, duplicate, or conversational text.

## Updating rules

- Update an existing rule in place when the behavior already belongs to it.
- Add a new rule only when it changes a generation or review decision.
- Keep examples short and specific to the rule.
- Preserve the required header.
