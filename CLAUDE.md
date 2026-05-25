# Project Instructions

## Context

This file is loaded into context. Keep it concise, explicit, and actionable.

Use this file as the entry point for every task in this repository.

## Context routing

Before answering questions or performing tasks, read [.claude/context/CLAUDE.md](.claude/context/CLAUDE.md). Use it to
choose which project context files to load before acting.

Keep `.claude/context/CLAUDE.md` portable across projects: it should route only to `SETUP.md` and `TECHNICAL.md`.
Project-specific secondary runbooks, such as cluster or registry setup files, should be referenced from `SETUP.md` or
`TECHNICAL.md` instead.

## Commit conventions

Apply these rules to every commit, whether or not the work belongs to a ticket.

**Never commit `CLAUDE.md` or any files in the `.claude/` directory.** These are local configuration files and should
not be pushed to the repository.

1. **Make each commit self-contained and testable.** Each commit must compile, pass its own verification step, and make
   sense without a later commit. Prefer small commits. Keep tightly coupled edits together, such as a rename and the
   references it forces. Put unrelated fixes in separate commits.
2. **Use a concise imperative subject.** State what changed.
3. **Use a bulleted body only when the commit has multiple changes.** Use one present-participle bullet per change.
   Example:
   ```
   - Adding a new AuthMiddleware class to centralize token validation
   - Removing unused legacy session cookie helpers
   - Updating LoginController to call AuthMiddleware before handler dispatch
   ```
   If the commit has one change, use only the subject. Do not add a one-bullet body that repeats the subject. If the
   reason is not obvious from the diff, add one short paragraph after the subject or bullets.

   Treat a self-contained, testable unit as one change. A class plus its tests is one change. A rename plus reference
   updates is one change. Feature-flag plumbing plus the gated feature is two changes when the plumbing is testable on
   its own.
4. **Prefix the subject line with the ticket ID when the commit belongs to a ticket.** Format:
   `<TICKET_ID>: <concise description>`. Example: `ABC-123: extract auth middleware into separate module`. A commit is
   considered a ticket commit if either: the ticket skill is active for a known `<TICKET_ID>`, OR the current branch
   name encodes a ticket ID (e.g. `feature/ABC-123-short-slug`, `bugfix/PROJ-4567`, `ABC-123/...`). For commits that do
   not belong to a ticket, omit the prefix.

For other ticket-specific commit conventions, see the ticket skill.

## Dependency changes

Before adding a new package, library, image dependency, CLI tool, OS package, or build/runtime dependency:

1. Identify the exact behavior that requires the dependency.
2. Verify the minimal dependency set locally when feasible. Vendor docs prove how to install something; they do not
   prove every package in an example is required here.
3. Add extra packages only after proving the minimal install or existing project tooling cannot satisfy the need.
4. Treat development headers, SDKs, compilers, `*-dev` packages, and build tools as default-reject in runtime images
   unless a compile step or runtime behavior proves they are required.
5. Record the proof in the ticket notes, durable docs, commit message, or final response: command run, output observed,
   source inspected, or the explicit reason verification was not possible.

## Style Guides

Before creating or modifying style guides, read [.claude/styles/CLAUDE.md](.claude/styles/CLAUDE.md).

Load a style guide when generating or reviewing files in that domain:

- [JAVA.md](.claude/styles/JAVA.md) — Optional chaining, service naming, DI patterns
- [POSTMAN.md](.claude/styles/POSTMAN.md) — Collection structure, test scripts, environment variables
