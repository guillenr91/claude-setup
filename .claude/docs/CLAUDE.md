# Documentation Guidelines

All paths in this file are relative to `.claude/docs/`. The referenced files (`SETUP.md`, `TECHNICAL.md`) live alongside
this one.

## Quick Reference

| Question Type           | Read                         |
|-------------------------|------------------------------|
| **How do I run this?**  | [SETUP.md](SETUP.md)         |
| **How does this work?** | [TECHNICAL.md](TECHNICAL.md) |

## Routing Rules

**Read SETUP.md when the task involves:**

- Running, building, or starting the application
- Setting up credentials, environment variables, or external service access
- Verifying permissions or troubleshooting startup failures
- IDE configuration or local development setup

**Read TECHNICAL.md when the task involves:**

- Debugging issues or investigating bugs
- Understanding code flow, architecture, or integrations
- Finding where something is configured or how components connect
- Data store schemas, error patterns, or environment differences

**Read both when:**

- Onboarding to the project for the first time
- The issue might be setup-related or code-related (unclear root cause)

---

## Keep Documentation In Sync

These files are living documents. Update them when you discover something not already captured:

- New troubleshooting solution → SETUP.md troubleshooting table
- New component behavior → TECHNICAL.md
- Verified command that wasn't documented → add it with the verified output
- New error and its solution → document both

When you update a file, refresh its `last-verified` date in the front matter (see "Staleness" below).

Before ending a session, check if anything learned should be persisted for future reference.

---

## Generating Missing Documentation

If `SETUP.md` or `TECHNICAL.md` does not exist, generate it through analysis of the project. Every command, path, and
configuration must be verified before being written, or explicitly marked unverified per "Verification Standards".

### SETUP.md

Purpose: zero to running application in one read.

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

1. Prerequisites
2. Clone and build
3. Credentials configuration
4. Permission verification commands (with success and failure output)
5. Environment variables
6. Run commands
7. Verify it works
8. IDE setup
9. Troubleshooting table
10. Quick reference table

### TECHNICAL.md

Purpose: understand the system well enough to debug or extend it.

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

1. Architecture overview
2. External integrations
3. Persistent stores (schemas, indexes)
4. Authentication and authorization flow
5. Environment configurations
6. Error handling and exceptions
7. Debugging techniques
8. Permission barriers

---

## Verification Standards

Verify everything you write. When you cannot verify something - missing credentials, sandboxed environment, no access to
a service - write the entry and mark it unverified rather than silently guessing or omitting it.

| Item               | Verification Method                   | If Unverifiable                    |
|--------------------|---------------------------------------|------------------------------------|
| Commands           | Run and confirm output                | Mark `Not verified - requires <X>` |
| Paths              | Confirm file exists                   | Mark `Not verified - requires <X>` |
| Configurations     | Read the actual config file           | Mark `Not verified - requires <X>` |
| External resources | Query with the appropriate CLI or SDK | Mark `Not verified - requires <X>` |
| Data store schemas | Describe the structure directly       | Mark `Not verified - requires <X>` |
| Error messages     | Reproduce to capture exact text       | Mark `Not verified - requires <X>` |

Unverified entries are acceptable. Unverified entries presented as fact are not.

---

## Staleness

`SETUP.md` and `TECHNICAL.md` should each begin with a YAML front matter block:

```yaml
---
last-verified: YYYY-MM-DD
---
```

Update this date whenever you re-verify the contents end-to-end, or when you make changes that you have re-verified. If
the date is more than a few months old, treat the contents as suspect and re-verify before relying on them for a
non-trivial action.
