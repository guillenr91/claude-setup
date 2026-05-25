# Style Guide Instructions

## Context

This file is loaded into context. Keep it concise, explicit, and actionable.

Use this file before creating or modifying any Markdown file in `.claude/styles/`.

## Required Header

Every style guide in this directory must start with this header pattern:

```markdown
# <Domain> Style Guide

## Context

This file is loaded into context. Keep it concise, explicit, and actionable.
```

After the header, add one short sentence explaining when to use the guide.

## Writing Rules

- Write rules as `### Rule: <imperative rule name>`.
- State the trigger before the action.
- Use `Do`, `Do not`, and `Exceptions` labels when they make the action clearer.
- Include examples only when they disambiguate the rule.
- Prefer existing project patterns when they conflict with a general style rule.
- Remove stale, duplicate, or conversational text.

## Updating Rules

- Update an existing rule in place when the behavior already belongs to that rule.
- Add a new rule only when it changes a generation or review decision.
- Keep examples short and specific to the rule they support.
- Preserve the required header when editing existing style guides.
