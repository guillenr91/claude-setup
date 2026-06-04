# Skill Instructions

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents — preserve this standard in
every future edit.

Use this file before creating or modifying any skill in `.claude/skills/`. Each skill lives in its own directory as
`.claude/skills/<skill-name>/SKILL.md` and is loaded only when triggered.

## Required header

Every `SKILL.md` must start with YAML frontmatter, then the title and standard opening line:

```markdown
---
name: <skill-name>
description: >-
  <one-sentence summary of what the skill does, plus explicit trigger conditions and
  non-trigger cases. The description IS the trigger logic — it must tell the agent
  when to invoke and when to skip.>
---

# <Skill Title>

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents — preserve this standard in
every future edit.
```

After the standard opening line, add one short sentence stating the skill's purpose.

## Writing rules

- **Be context-efficient.** Every line that loads into context must earn its place. Cut conversational filler,
  duplicated content, and prose that restates structure.
- **Be unambiguous.** State triggers before actions. Use imperative verbs (Do, Do not, Stop, Ask).
- **Be actionable.** Each instruction should map to a concrete decision or operation the agent can perform.
- **Use templates for repeated structures.** When a skill writes files, give the agent a fenced template with
  placeholder syntax it can fill in.
- **Prefer short numbered steps over prose** when the order matters.
- **Prefer bullets over paragraphs** when the order does not matter.
- **No marketing language, no apologies, no hedging.** "This is an important step" / "you may want to consider" /
  "feel free to" — all cut.

## Updating skills

- Update an existing rule in place when the behavior already belongs to it.
- Add a new section only when it changes a decision the agent makes.
- When pruning, preserve every actionable rule. Cosmetic phrasing changes are fine; rule drops require deliberate
  judgment.
- Preserve the required header (YAML frontmatter + title + standard opening line) when editing existing skills.
