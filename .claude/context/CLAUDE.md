# Context Guide

## Context

This file is loaded into context. Keep it concise, explicit, and actionable.

Use this file to decide which project context to load. All paths here are relative to `.claude/context/`.

## Quick Reference

| Task asks about          | Read                         |
|--------------------------|------------------------------|
| Running or configuring   | [SETUP.md](SETUP.md)         |
| Architecture or behavior | [TECHNICAL.md](TECHNICAL.md) |
| Unclear root cause       | Both                         |

## Routing Rules

Read `SETUP.md` when the task involves:

- Running, building, or starting the application
- Setting up credentials, environment variables, or external service access
- Verifying permissions or troubleshooting startup failures
- IDE configuration or local development setup

Read `TECHNICAL.md` when the task involves:

- Debugging issues or investigating bugs
- Understanding code flow, architecture, or integrations
- Finding where something is configured or how components connect
- Data store schemas, error patterns, or environment differences

Read both files when:

- Onboarding to the project for the first time
- The issue might be setup-related or code-related (unclear root cause)

---

## Keep Documentation In Sync

Update durable project context when you discover information a future assistant or developer will need:

- New troubleshooting solution: add it to `SETUP.md`.
- New component behavior: add it to `TECHNICAL.md`.
- Verified command that was not documented: add the command and observed output.
- New error and solution: document both the error and the fix.

When you update `SETUP.md` or `TECHNICAL.md`, refresh its `last-verified` date only for content you re-verified.

Before ending a session, check if anything learned should be persisted for future reference.

## Table Of Contents Requirement

`SETUP.md` and `TECHNICAL.md` must each include a table of contents near the top of the file, after the `## Context`
header and any introductory paragraph.

When generating either file, create the table of contents before the first main section. When updating either file,
verify the table of contents still matches the headings you changed. If the file has no table of contents, add one as
part of the same update before ending the task. Do not finish a documentation update that leaves `SETUP.md` or
`TECHNICAL.md` without a current table of contents.

---

## Generating Missing Documentation

If `SETUP.md` or `TECHNICAL.md` does not exist, generate it from verified project evidence. Every command, path, and
configuration must either be verified before being written or marked unverified per "Verification Standards".

### Required Header

Generated `SETUP.md` and `TECHNICAL.md` files must start with this header pattern:

```markdown
# <Document Title>

## Context

This file is loaded into context. Keep it concise, explicit, and actionable.
```

After the header, add one short sentence explaining the file's purpose.

### SETUP.md

Purpose: explain how to get from a fresh checkout to a running, verified application.

Generate by:

1. Identify the build system and required language runtime and version
2. Identify external dependencies (cloud services, databases, caches, message queues, feature flags, secret stores)
3. Discover required credentials and environment variables
4. Test build and run commands until they succeed
5. Identify common failure modes and their solutions

Verify by:

- Running each command and capturing actual output
- Testing credential and permission commands with real access
- Starting the application and confirming it responds correctly
- Reproducing documented errors to capture exact messages

Required sections:

0. Context header and table of contents.
1. Prerequisites.
2. Clone and build.
3. Credentials configuration.
4. Permission verification commands, including success and failure output.
5. Environment variables.
6. Run commands.
7. Verification steps.
8. IDE setup.
9. Troubleshooting table.
10. Quick reference table.

### TECHNICAL.md

Purpose: explain how the system works well enough to debug or extend it.

Generate by:

1. Trace startup flow - what is loaded and from where
2. Map external integrations and their configuration sources
3. Identify persistent stores and their purposes (tables, collections, indexes, topics)
4. Document authentication and authorization patterns
5. Understand differences across environments (local, dev, staging, prod)
6. Catalog error codes, exceptions, and known failure modes

Verify by:

- Reading source code, not only configuration
- Querying data stores to confirm structures
- Tracing real API calls to understand auth flow
- Testing in each environment when access permits

Required sections:

0. Context header and table of contents.
1. Architecture overview.
2. External integrations.
3. Persistent stores, including schemas and indexes.
4. Authentication and authorization flow.
5. Environment configurations.
6. Error handling and exceptions.
7. Debugging techniques.
8. Permission barriers.

---

## Verification Standards

Verify everything you write. When something cannot be verified because credentials, services, or environment access are
missing, mark it unverified instead of guessing.

| Item               | Verification Method                   | If Unverifiable                    |
|--------------------|---------------------------------------|------------------------------------|
| Commands           | Run and confirm output                | Mark `Not verified - requires <X>` |
| Paths              | Confirm file exists                   | Mark `Not verified - requires <X>` |
| Configurations     | Read the actual config file           | Mark `Not verified - requires <X>` |
| External resources | Query with the appropriate CLI or SDK | Mark `Not verified - requires <X>` |
| Data store schemas | Describe the structure directly       | Mark `Not verified - requires <X>` |
| Error messages     | Reproduce to capture exact text       | Mark `Not verified - requires <X>` |

Unverified entries are acceptable. Unverified entries presented as fact are defects.

---

## Staleness

`SETUP.md` and `TECHNICAL.md` should each begin with a YAML front matter block:

```yaml
---
last-verified: YYYY-MM-DD
---
```

Update this date when you re-verify the file end to end, or when every changed entry has been re-verified. If the date
is more than a few months old, treat the file as suspect and re-verify before relying on it for a non-trivial action.
