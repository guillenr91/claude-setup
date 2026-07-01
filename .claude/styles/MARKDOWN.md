# Markdown Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Read before creating or editing any Markdown file that contains commands, setup steps, or procedures.

### Rule: Prefer verified commands over prose

Trigger: writing repeatable setup, verification, migration, troubleshooting, or review steps.
Do: use verified parameterized commands or scripts when shorter and safer than prose.

### Rule: Ready-to-run commands need eight fields

Trigger: documenting a command for setup, deployment, migration, troubleshooting, or any destructive or stateful
operation.
Do: include working directory, prerequisites, placeholders, replacement values, command run, relevant environment,
success signal, and verification date.
Exception: one-off read-only commands quoted inline in chat (`ls`, `grep`, `cat` shown to illustrate a finding)
need only the command itself and any non-obvious context.

### Rule: Label templates as templates

Trigger: writing a command that contains placeholders or has not been executed as-is.
Do: mark it as a template, state replacements, and do not present it as verified until run.

### Rule: Never embed secrets or machine-specific paths

Trigger: writing any command or example.
Do not: embed secrets, tokens, passwords, private keys, session values, personal credentials, or machine-specific
paths.

### Rule: Prefer scripts for multi-step reuse

Trigger: documenting a procedure that will run more than once or in more than one environment.
Do: write a script that takes arguments or environment variables, fails clearly, avoids destructive defaults, and
supports dry-run, read-only, or validation modes when practical.

### Rule: Mark unverified commands

Trigger: including a command you have not executed in this session.
Do: mark it `Not verified - requires <X>`. Do not create confident copy-paste traps.
