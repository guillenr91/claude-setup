# Context Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Use this file to decide which project context to load. All paths relative to `.claude/context/`. Keep this file
portable: limit it to generic routing between `SETUP.md` and `TECHNICAL.md`. Project-specific routing belongs in
`SETUP.md` or `TECHNICAL.md`, not here.

## Routing

| Task involves                                     | Read                         |
|---------------------------------------------------|------------------------------|
| Running, building, starting the app               | [SETUP.md](SETUP.md)         |
| Credentials, env vars, external service access    | [SETUP.md](SETUP.md)         |
| Permissions, startup failures, IDE setup          | [SETUP.md](SETUP.md)         |
| Debugging, code flow, architecture, integrations  | [TECHNICAL.md](TECHNICAL.md) |
| Where something is configured, how things connect | [TECHNICAL.md](TECHNICAL.md) |
| Schemas, error patterns, environment differences  | [TECHNICAL.md](TECHNICAL.md) |
| First-time onboarding, unclear root cause         | Both                         |

## Keep documentation in sync

Update durable project context when you discover information a future assistant or developer will need:

- New troubleshooting solution → `SETUP.md`.
- New component behavior → `TECHNICAL.md`.
- Verified command not yet documented → add the command and observed output.
- New error and solution → document both.
- Project-specific secondary context files may be referenced from `SETUP.md` or `TECHNICAL.md`. Keep those routes out
  of this portable guide.

When you update `SETUP.md` or `TECHNICAL.md`, refresh `last-verified` only for content you re-verified. Before ending
a session, check whether anything learned should be persisted.

## Required structure for SETUP.md and TECHNICAL.md

Both files must:

1. Start with YAML front matter:
   ```yaml
   ---
   last-verified: YYYY-MM-DD
   ---
   ```
2. Open with this header pattern, followed by one short sentence stating the file's purpose:
   ```markdown
   # <Document Title>

   Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting
   around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future
   edit.
   ```
   The one-sentence purpose statement is required, not optional.
3. Include a table of contents after the `## Context` header and intro sentence, before the first main section. When
   updating either file, verify the TOC still matches changed headings; if missing, add one as part of the same update.
   Do not finish a documentation update that leaves either file without a current TOC.

If `last-verified` is more than a few months old, treat the file as suspect and re-verify before relying on it.

## Generating SETUP.md or TECHNICAL.md when missing

Generate from verified project evidence. Every command, path, and configuration must either be verified or marked
unverified per "Verification Standards" below.

### SETUP.md

Purpose: get from a fresh checkout to a running, verified application.

Generate by:

1. Identify the build system and required language runtime + version.
2. Identify external dependencies (cloud services, databases, caches, queues, feature flags, secret stores).
3. Discover required credentials and environment variables.
4. Test build and run commands until they succeed.
5. Identify common failure modes and their solutions.

Verify by:

- Running each command and capturing actual output.
- Testing credential and permission commands with real access.
- Starting the application and confirming it responds correctly.
- Reproducing documented errors to capture exact messages.

Required sections (in order): Context header & TOC, Prerequisites, Clone and build, Credentials configuration,
Permission verification commands (with success and failure output), Environment variables, Run commands, Verification
steps, IDE setup, Troubleshooting table, Quick reference table.

### TECHNICAL.md

Purpose: explain how the system works well enough to debug or extend it.

Generate by:

1. Trace startup flow — what is loaded and from where.
2. Map external integrations and their configuration sources.
3. Identify persistent stores and their purposes (tables, collections, indexes, topics).
4. Document authentication and authorization patterns.
5. Understand differences across environments (local, dev, staging, prod).
6. Catalog error codes, exceptions, and known failure modes.

Verify by:

- Reading source code, not only configuration.
- Querying data stores to confirm structures.
- Tracing real API calls to understand auth flow.
- Testing in each environment when access permits.

Required sections (in order): Context header & TOC, Architecture overview, External integrations, Persistent stores
(schemas + indexes), Authentication and authorization flow, Environment configurations, Error handling and
exceptions, Debugging techniques, Permission barriers.

## Verification standards

Verify everything you write. When something cannot be verified (missing credentials, services, or env access), mark
it unverified instead of guessing. Unverified entries are acceptable. Unverified entries presented as fact are defects.

| Item               | Verification method                   | If unverifiable                    |
|--------------------|---------------------------------------|------------------------------------|
| Commands           | Run and confirm output                | Mark `Not verified - requires <X>` |
| Paths              | Confirm file exists                   | Mark `Not verified - requires <X>` |
| Configurations     | Read the actual config file           | Mark `Not verified - requires <X>` |
| External resources | Query with the appropriate CLI or SDK | Mark `Not verified - requires <X>` |
| Data store schemas | Describe the structure directly       | Mark `Not verified - requires <X>` |
| Error messages     | Reproduce to capture exact text       | Mark `Not verified - requires <X>` |
