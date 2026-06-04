# Style Guide Instructions

Loaded into context when read. Keep concise, explicit, and actionable for AI agents — preserve this standard in every
future edit.

Read this before creating or modifying any Markdown file in `.claude/styles/`. Every guide in this directory is a
required pre-read before generating or reviewing work in its domain. Name new guides by domain (`JAVA.md`,
`POSTMAN.md`, etc.) so the matching file is obvious.

## Required header

Every style guide must start with:

```markdown
# <Domain> Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents — preserve this standard in every
future edit.
```

After the header, add one short sentence explaining when to use the guide.

## Writing rules

- Format each rule as `### Rule: <imperative rule name>`.
- State the trigger before the action.
- Use `Do`, `Do not`, and `Exceptions` labels when they sharpen the action.
- Include examples only when they disambiguate.
- Prefer existing project patterns when they conflict with a general rule.
- Remove stale, duplicate, or conversational text.

## Updating rules

- Update an existing rule in place when the behavior already belongs to it.
- Add a new rule only when it changes a generation or review decision.
- Keep examples short and specific to the rule.
- Preserve the required header.
