# Skill Instructions

Apply the global `# Context` brevity and formatting rules to this file.

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

Apply the global `# Context` brevity and formatting rules to this file.
```

After the standard opening line, add one short sentence stating the skill's purpose.

## Writing rules

- Be context-efficient. Every line that loads into context must earn its place. Cut conversational filler, duplicated content, and prose that restates structure.
- Be unambiguous. State triggers before actions. Use imperative verbs (Do, Do not, Stop, Ask).
- Be actionable. Each instruction maps to a concrete decision or operation the agent can perform.
- Use templates for repeated structures. When a skill writes files, provide a fenced template with placeholder syntax.
- Prefer short numbered steps when order matters; bullets otherwise.
- No marketing language, no apologies, no hedging. "This is an important step" / "you may want to consider" / "feel free to" — all cut.

## Updating skills

- Apply the global `# Instruction deduplication` rules.
- When pruning, preserve every actionable rule. Cosmetic phrasing changes are fine; rule drops require deliberate judgment.
- Preserve the required header (YAML frontmatter + title + standard opening line) when editing existing skills.
