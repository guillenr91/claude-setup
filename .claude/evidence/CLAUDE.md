# Evidence Record Guide

Loaded into context when read. Keep brief and concise, explicit, and actionable for AI agents. Preserve every concrete instruction and action; cut verbose prose. No decorative formatting around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Stores project-level evidence only when no ticket is active. For ticket work, store records in `.claude/context/tickets/<TICKET_ID>/evidence/`. The `evidence-first` skill owns verification and reuse decisions.

## Records

- Create one `<claim-id>.md` file per eligible atomic claim. Use a stable, descriptive kebab-case name.
- Use only the six `evidence-first` template fields: `claim`, `source`, `check`, `expected`, `verified`, and `proof`. Do not add a title, headings, analysis, or duplicated source text.
- Keep `proof` to 40 words or five code lines maximum.
- Store only non-sensitive evidence. Never include secrets, tokens, credentials, personal data, or private values.
- Update a record only after direct verification. Delete or replace a record when its source no longer supports its claim.

## Reuse

- Reuse requires a fresh exact match from the record's fingerprint command.
- Do not reuse records for runtime state, command or test results, deployments, credentials, mutable URLs, or any source without a deterministic fingerprint.
- A challenged claim requires direct re-verification; do not reuse its record.
