# Project Context

**Before answering questions or performing tasks**, read [.claude/docs/CLAUDE.md](.claude/docs/CLAUDE.md) to determine
which documentation file to consult.

# Commit conventions

These apply to every commit, whether or not the work belongs to a ticket.

**Never commit `CLAUDE.md` or any files in the `.claude/` directory.** These are local configuration files that should not be pushed to the repository.

1. **Self-contained, testable commits.** Each commit must compile, pass its own verification step, and not depend on a
   later commit to make sense. Prefer small commits, but group closely-related changes when splitting them would be
   artificial (e.g. a class and its tests, a rename and the call-site updates it forces). Do not bundle unrelated
   changes — drive-by fixes belong in their own commit.
2. **Concise but descriptive subject line.** Imperative mood, stating what changed.
3. **Bulleted body listing the changes when there is more than one change.** Use one bullet per change, in
   present-participle form. Example:
   ```
   - Adding a new AuthMiddleware class to centralize token validation
   - Removing unused legacy session cookie helpers
   - Updating LoginController to call AuthMiddleware before handler dispatch
   ```
   If the commit contains a single change, the subject line stands on its own — do not add a one-bullet body that just
   restates it. Keep bullets concise and specific. If a change's *why* is non-obvious from the diff, add a short prose
   paragraph below the bullets (or below the subject, for single-change commits) to capture the reasoning.

   *What counts as one change:* a self-contained, testable unit, per rule 1. A new class plus its tests is one change (
   the empty class isn't independently testable). A rename plus the call-site updates it forces is one change (the
   half-renamed state doesn't compile). Adding feature-flag plumbing plus the feature it gates is two changes (the
   plumbing is testable on its own).
4. **Prefix the subject line with the ticket ID when the commit belongs to a ticket.** Format:
   `<TICKET_ID>: <concise description>`. Example: `ABC-123: extract auth middleware into separate module`. A commit is
   considered a ticket commit if either: the ticket skill is active for a known `<TICKET_ID>`, OR the current branch
   name encodes a ticket ID (e.g. `feature/ABC-123-short-slug`, `bugfix/PROJ-4567`, `ABC-123/...`). For commits that do
   not belong to a ticket, omit the prefix.

For other ticket-specific commit conventions, see the ticket skill.

# Code style

## Null handling — Optional chaining over if statements

Use `Optional` with `.map()`, `.filter()`, `.orElse()` instead of cascading null checks. Return `Optional<T>` from helper methods that perform extraction or lookup.

```java
// CORRECT
return extractSerialNumber(deviceId)
        .map(sn -> dataProvider.getEligibility(sn))
        .filter(Eligibility::isTrialUsed)
        .filter(e -> e.getEndDate() != null && e.getEndDate() > 0)
        .map(e -> buildDto(e))
        .orElse(null);

// WRONG
String sn = extractSerialNumber(deviceId);
if (sn == null) return null;
Eligibility e = dataProvider.getEligibility(sn);
if (e == null) return null;
if (!e.isTrialUsed()) return null;
if (e.getEndDate() == null) return null;
return buildDto(e);
```
