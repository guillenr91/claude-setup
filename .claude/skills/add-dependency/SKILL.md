---
name: add-dependency
description: >-
  Rules for adding any package, library, image dependency, CLI tool, OS
  package, or build/runtime dependency. Invoke before editing dependency
  manifests (`package.json`, `pom.xml`, `build.gradle`, `requirements.txt`,
  `Pipfile`, `Gemfile`, `go.mod`, `Cargo.toml`, `Dockerfile`, apt/brew/yum
  install lines) to add a new entry, and before installing a new CLI tool
  or OS package. Do not invoke for version bumps of existing dependencies
  or for removing dependencies.
---

# Add Dependency Skill

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Gate for introducing new dependencies of any kind.

Before adding any package, library, image dependency, CLI tool, OS package, or build/runtime dependency:

1. Identify the exact behavior that requires it.
2. Verify the minimal dependency set locally when feasible. Vendor docs prove how to install something; they do not
   prove every package in an example is required here.
3. Add extras only after proving the minimal install or existing project tooling cannot satisfy the need.
4. Default-reject development headers, SDKs, compilers, `*-dev` packages, and build tools in runtime images unless a
   compile step or runtime behavior proves they are required.
5. Record proof in ticket notes, durable docs, commit message, or final response: command run, output observed, source
   inspected, or explicit reason verification was not possible.
