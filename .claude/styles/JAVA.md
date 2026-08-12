# Java Style Guide

Loaded into context when read. Keep concise, explicit, and actionable for AI agents. No decorative formatting around
prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Use these rules when generating or reviewing Java code. Apply a rule only when its trigger matches. Prefer existing
project patterns when they conflict with a rule here.

## Simplicity

### Rule: choose the simplest readable shape

Trigger: multiple valid ways to express the same Java behavior.

Do: choose the version with the fewest moving parts that still names the project concept clearly.

Do not: add helpers, constants, comments, records, abstractions, or extra line breaks unless they remove real
complexity or protect a real invariant.

Exception: accept a slightly longer shape when it makes failure behavior, resource ownership, or externally
visible validation clearer.

### Rule: avoid ceremony around one clear validation rule

Trigger: validation reads as one rule (e.g. "required and non-empty", "present and parseable").

Do: express it as one direct chain or expression when the error is the same for all invalid states.

Do not: introduce temporary variables, separate null checks, or small helper methods that only restate the rule.

Use the `Optional` pattern in "derive required values from optional helpers" when starting from an existing optional
helper.

### Rule: keep formatting compact when it stays readable

Trigger: formatting method calls, lambdas, builders, or exceptions.

Do: keep short related arguments together; wrap only at boundaries that improve scanning.

Do not: add vertical space or line breaks just because an expression has multiple parts.

Exception: wrap aggressively when the line hides a condition, repeats long expressions, or exceeds the project's
formatter conventions.

## Reuse existing helpers first

### Rule: scan for existing utilities before writing new logic

Trigger: about to write null-safety plumbing, iteration+filter boilerplate, a projection, a small validation, or
any short piece of logic that "feels generic enough that someone probably wrote it already."

Do: before writing it, scan the project's shared utility packages (`.../utils/`, `.../common/`, `.../helper/`,
and analogous libjava modules the project depends on). Grep for the noun or verb at the center of what you're
about to write — collection, stream, non-null, non-empty, optional, retry, parse, validate. If a helper already
exists, use it directly and take the null-safety, empty-safety, and formatting choices it encodes.

Do not: reimplement the same shape inline. Repeated ad-hoc `Optional.ofNullable(list).orElse(emptyList()).stream()`,
`if (x == null) continue`, or `list.stream().filter(Objects::nonNull)` around every call are signs a shared helper
was skipped.

Exception: build a new helper only when the existing one does not fit the exact shape you need. When you introduce
a new helper, put it in the shared utility package so the next scan finds it.

```java
// Do
Utils.nonNullNonEmptyStream(locations).forEach(location -> ...);
Utils.nonNullNonEmptyStream(location.getPlans()).map(PlanModel::getPlanCode)...

// Do not
for (Location location : locations) {
    if (location == null || CollectionUtils.isEmpty(location.getPlans())) {
        continue;
    }
    location.getPlans().stream().filter(Objects::nonNull)...
}
```

This is a "before you write" habit, not a post-hoc cleanup. A quick grep in the shared utility package is cheaper
than a code review round.

## Null handling

### Rule: prefer `Optional` chaining over cascading null checks

Trigger: a method threads a value through two or more sequential nullable lookups, transformations, or filters.

Do: express the flow as one `Optional` chain when it stays readable.

Do not: write `if (x == null) return ...;` guards in series.

Exceptions (write the imperative form instead):
- Single null check with an immediate return.
- Tight loop where allocation pressure has been measured and matters.
- Steps that must throw distinct exceptions on absence — the chain hides which step produced the absence.

```java
return findUserId(request)
        .map(userRepository::find)
        .filter(User::isActive)
        .filter(user -> user.lastLogin() != null)
        .map(this::toDto)
        .orElse(null);
```

### Rule: use `Optional.orElseThrow` when a single null check must throw

Trigger: a call may return `null` and the reaction is to log-and-throw a runtime exception.

Do: write it as `Optional.ofNullable(call(...)).orElseThrow(() -> ...)`. Use a block-body lambda so the exception
factory can log context before returning the exception.

Do not: introduce a local variable followed by `if (value == null) { log(...); throw new ...; }`. That splits one
guard across three statements and separates the log message from the throw.

Exception: keep the imperative form when several distinct null/state checks apply to the same value and lifting
one into `Optional` would leave the others behind in imperative form.

```java
private Response fetchThing(final String id) {
    try {
        return Optional.ofNullable(client.get(id))
                .orElseThrow(() -> {
                    log.error("Client returned null for id: {} - treating as service failure", id);
                    return new IllegalStateException("Client returned null for id: " + id);
                });
    } catch (RuntimeException e) {
        log.error("Client call failed for id: {} - downstream service error", id, e);
        throw e;
    }
}
```

The surrounding `try/catch (RuntimeException e)` still handles thrown exceptions; the `Optional` chain handles
the `null` return.

Related: "Rule: prefer `Optional` chaining over cascading null checks" — the exception there for "Single null
check with an immediate return" applies only when the reaction is to *return* a value, not to throw.

### Rule: collapse a nullable fetch and its empty-default into a fetch helper

Trigger: a caller pattern that (1) invokes a nullable fetch, (2) short-circuits when the result is `null` or
empty, and (3) then streams / transforms the value. Especially common when the empty short-circuit returns a
default like `Collections.emptyList()`.

Do: extract the fetch into a helper whose entire body is
`Optional.ofNullable(nullableCall(...)).orElse(<empty default>)`. Let the calling method be a single fluent
expression that starts from that helper.

Do not: keep a local variable, a separate `CollectionUtils.isEmpty(...) return Collections.emptyList()` guard,
and then a stream in the same method. It splits a single "load-or-empty" concept across four statements when a
one-liner helper expresses it directly.

Exception: when the caller needs to distinguish "null response" from "empty result" (different logs, different
metrics, different downstream behavior), keep the guards imperative in the caller so each case can act
distinctly.

```java
// Do
private List<Item> getItems(final String key) {
    try {
        return Optional.ofNullable(client.fetch(key))
                .orElse(Collections.emptyList());
    } catch (RuntimeException e) {
        log.error("Failed to fetch items for key: {} - downstream error", key, e);
        throw e;
    }
}

private List<Item> getActiveItems(final String key) {
    return getItems(key)
            .stream()
            .filter(Objects::nonNull)
            .filter(Item::isActive)
            .collect(Collectors.toList());
}

// Do not
private List<Item> getActiveItems(final String key) {
    List<Item> items;
    try {
        items = client.fetch(key);
    } catch (RuntimeException e) {
        log.error("Failed to fetch items for key: {} - downstream error", key, e);
        throw e;
    }
    if (CollectionUtils.isEmpty(items)) {
        return Collections.emptyList();
    }
    return items.stream()
            .filter(Objects::nonNull)
            .filter(Item::isActive)
            .collect(Collectors.toList());
}
```

This is the sibling of the "`Optional.orElseThrow` when a single null check must throw" rule: same
`Optional.ofNullable(nullableCall()).<terminal>(...)` shape, but the terminal is a default value instead of an
exception. Use `orElse` for a cheap literal like `Collections.emptyList()` or `""`; use `orElseGet` when the
default construction is not free.

### Rule: helpers return `Optional<T>`, not `null`

Trigger: writing or modifying a helper that performs extraction or lookup and may have no result.

Do: declare the return type as `Optional<T>`.

Exception: keep `null` when a public API, framework contract, downstream service, or persisted schema already
defines `null` semantics. Do not change those contracts without coordination.

### Rule: terminate the chain only at a non-`Optional` boundary

Do:
- Return `Optional<T>` from helpers so callers can keep chaining.
- Use `.orElse(...)` / `.orElseThrow(...)` / `.orElseGet(...)` only in methods whose return type is fixed and
  non-`Optional`.

Do not: end a helper's chain with `.orElse(null)` and force every caller to re-wrap with `Optional.ofNullable(...)`.

```java
public Optional<User> findActiveUser(Request request) {
    return findUserId(request)
            .map(userRepository::find)
            .filter(User::isActive);
}

public UserDto getUser(Request request) {
    return findActiveUser(request)
            .map(this::toDto)
            .orElse(null);
}
```

### Rule: derive required values from optional helpers

Trigger: a required value is the non-empty form of an existing `Optional<T>` helper, and absence should produce
one clear validation error.

Do: use the optional helper, filter invalid values, terminate with `.orElseThrow(...)`.

Do not: repeat the raw lookup with separate null and empty checks.

Exception: use imperative checks when each invalid case needs a distinct error or side effect.

```java
private String required(String name) {
    return optional(name)
            .filter(value -> !value.isEmpty())
            .orElseThrow(() -> new IllegalArgumentException("Missing required environment variable: '" + name + "'"));
}
```

## Runtime entrypoints and config

### Rule: keep process exits at the entrypoint

Trigger: writing a Java helper, CLI, hook, Job runner, or other executable class.

Do: let `main` translate failures into logs and exit codes. Let lower-level methods return values or throw
focused exceptions.

Do not: call `System.exit(...)` from parsing, retry, database, or business helpers. It makes code harder to test
and hides which layer owns failure handling.

### Rule: parse runtime configuration once

Trigger: code reads environment variables, system properties, command-line values, or external configuration in
more than one method.

Do: validate configuration near the entrypoint and pass a small immutable object (e.g. a `record`) to the code
that needs it.

Do not: read `System.getenv(...)`, parse numbers, or validate required settings inside every helper that needs
a value.

Exception: read directly when the method is the only consumer and creating a config object adds no clarity.

## Helpers and comments

Use comments to explain project contracts and non-obvious intent in the fewest useful words. The fluent-pipeline
rules apply to `Optional` and `Stream` chains, including `.filter`, `.map`, `.flatMap`, `.reduce`, `.collect`,
`.sorted`, and `.takeWhile`.

### Rule: a helper's name and return type must match a single responsibility

Trigger: writing or refactoring a private helper that fetches / loads / builds a value.

Do: stop the helper at the raw returned type. If callers need a projection (flattening, defaulting, filtering,
unwrapping), let each caller do it at the call site.

Do not: bake a caller-specific reshape (e.g. flattening a response to one of its inner lists, or defaulting a
nested field) into the helper. It hides the raw value from other callers, forces a second helper when a caller
needs it, and produces a name that describes only the last transformation.

Exception: keep the reshape inside the helper when every call site needs the same one AND the raw form has no
other useful reader. In that case, name the helper after the reshape (`loadEnabledUserIds`, not `loadUsers`).

### Rule: name a method for the check it actually performs

Trigger: naming or renaming a method that returns a filtered / validated / selected value.

Do: pick a name that matches exactly the filter(s) the method applies. If it selects by one attribute, name it
after that attribute. If a qualifier in the name implies a check the method does not perform, remove the
qualifier or add the check.

Do not: use qualifiers like `Active`, `Valid`, `Enabled`, `Live`, `Current` when the method does not enforce
that state. A future reader will assume the guarantee holds and skip re-adding it upstream, silently reintroducing
a bug.

```java
// Do — name matches behavior
private List<Subscription> getPlanSubscriptions(final String userId) {
    return getUserSubscriptions(userId)
            .stream()
            .filter(sub -> PlanCatalog.isPlan(sub.getPlanCode()))
            .collect(Collectors.toList());
}

// Do not — name promises "active" but method only filters by plan code
private List<Subscription> getActivePlanSubscriptions(final String userId) {
    return getUserSubscriptions(userId)
            .stream()
            .filter(sub -> PlanCatalog.isPlan(sub.getPlanCode()))
            .collect(Collectors.toList());
}
```

If the qualifier is load-bearing (a caller genuinely depends on it), add the check the name promises; do not
remove the qualifier and leave the semantic gap.

### Rule: split orchestration from per-item transformation

Trigger: a method (a) fetches / precomputes shared state, (b) iterates a collection, and (c) does non-trivial
work per item (nested loops, multi-step filtering, per-item state). It reads like two responsibilities layered
together — one method's worth of orchestration, one method's worth of per-item logic.

Do: keep the orchestrator short — fetch inputs, precompute lookups, then loop and delegate each item to a
per-item helper whose signature makes the inputs it needs explicit. The orchestrator's for-loop should be one
or two lines.

Do not: keep 30+ lines of nested per-item work inline in the orchestrator. It hides which state is shared
across items vs. scoped to one item, and it makes each responsibility harder to test in isolation.

```java
// Do
private List<Entry> buildEntries(final String key, final List<Item> items) {
    Map<String, Set<String>> indexByGroup = buildIndex(loadGroups(key));
    Set<String> supersededGroups = findSupersededGroups(loadGroups(key), key);

    List<Entry> result = new ArrayList<>();
    for (Item item : items) {
        result.addAll(buildEntriesForItem(key, item, indexByGroup, supersededGroups));
    }
    return result;
}

private List<Entry> buildEntriesForItem(final String key,
                                        final Item item,
                                        final Map<String, Set<String>> indexByGroup,
                                        final Set<String> supersededGroups) {
    // Per-item logic — filter groups, apply validators, emit entries.
    ...
}

// Do not
private List<Entry> buildEntries(final String key, final List<Item> items) {
    Map<String, Set<String>> indexByGroup = buildIndex(loadGroups(key));
    Set<String> supersededGroups = findSupersededGroups(loadGroups(key), key);

    List<Entry> result = new ArrayList<>();
    for (Item item : items) {
        // 30+ lines of nested filter/emit logic here.
        ...
    }
    return result;
}
```

Exception: keep the work inline when the per-item block is genuinely a handful of lines with no nested loops
and no independent responsibility — a for-loop that only appends one derived value per item is not two
responsibilities.

Prefer a per-item helper that returns a `List<Entry>` (or `Collection<Entry>`) and let the orchestrator use
`result.addAll(...)`. A helper that mutates a shared accumulator passed by reference is harder to test and
reads as a side-effecting procedure.

```java
// Do
private LookupResponse loadLookup(final String key) {
    return Optional.ofNullable(client.fetch(key))
            .orElseThrow(() -> {
                log.error("Client returned null for key: {}", key);
                return new IllegalStateException("Client returned null for key: " + key);
            });
}

// Caller: reshape at the call site.
List<Item> items = Optional.ofNullable(loadLookup(key).getItems())
        .orElse(Collections.emptyList());

// Do not: bake the projection into the helper, forcing every caller into that shape.
private List<Item> loadItems(final String key) {
    LookupResponse response = loadLookup(key);
    return Optional.ofNullable(response.getItems()).orElse(Collections.emptyList());
}
```

The compact `Optional.ofNullable(...).orElse(...)` at the call site is the "Rule: avoid ceremony around one clear
validation rule" shape applied to a defaulting projection.

### Rule: inline trivial single-use helpers

Trigger: a private helper has one call site and only wraps a simple expression, pass-through constructor, or
obvious library call.

Do: inline the expression at the call site; add a concise comment there when the reason isn't obvious.

Do not: keep a helper only to name a one-line expression like `Math.min(limit, value)`,
`Optional.ofNullable(value)`, or `super(message, cause)`.

Exception: keep the helper when it names a meaningful project concept, protects a non-obvious invariant, is
likely to gain additional call sites, or keeps a fluent chain readable.

### Rule: prefer Javadoc blocks over line comments for anything a reader might inspect

Trigger: about to attach an explanatory comment to a declaration — class, interface, enum, record, method,
constructor, field, constant, inner type, annotation type, or interface method.

Do: put the explanation in a Javadoc `/** ... */` block placed directly above the declaration. Javadoc renders
in IDE hover tooltips, generated docs, and code-review UIs, and signals the text is part of the contract.

Do not: use `//` line comments above a declaration to carry that explanation, even for one-liners. Line comments
above declarations read as scratch notes and don't surface in tooling.

Reserve `//` line comments for scratch or step-level explanations INSIDE method bodies (a single expression in a
chain, a non-obvious branch, a workaround for upstream data). See "Rule: comment non-obvious steps; do not
comment obvious ones" for what belongs there and what doesn't.

Exception: skip the Javadoc block entirely when the identifier plus type already tell the whole story (e.g.
`MILLIS_PER_SECOND`, `MAX_RETRIES`, a private setter that mirrors its field). In those cases add no comment at
all — an empty Javadoc block is worse than none.

```java
/**
 * Values below 10^<N> are <unit-A> (<M> digits today); values at or above are <unit-B> (<K> digits). Threshold
 * stays unambiguous through ~year <Y>.
 */
private static final long UNIT_BOUNDARY = 1_000_000_000_000L;
```

### Rule: use Javadoc for Java contracts that newcomers must understand

Trigger: writing or modifying a class, constructor, method, record, interface method, or custom exception whose
purpose, inputs, outputs, failure behavior, or project role isn't obvious to someone new to Java or the project.

Do: write a descriptive but concise standard Javadoc block with:

- Short first sentence explaining what the code does in project terms.
- Optional short `<p>` paragraph when runtime conditions, environment variables, or operational context are needed.
- `@param` for every parameter when the method takes arguments.
- `@return` when the method returns a value.
- `@throws` for checked exceptions and for runtime exceptions that are part of the contract.
- `{@link TypeName}` for Java symbols and `{@code literal}` for env vars, values, commands, URL fragments.
- A `javadoc -Xdoclint` verification step when changing non-trivial Javadocs.

Do not: use invalid Javadoc tags like `{@Config}` (use `{@link Config}`). Don't explain Java syntax, restate the
method name, or write Javadoc that says nothing beyond "gets X" / "sets Y". Don't add Javadoc to obvious one-line
wrappers or pass-through constructors (e.g. a method that only returns `Optional.ofNullable(value)`, or a constructor
that only calls `super(message, cause)`). Don't turn Javadoc into a README — move long operational lists to durable
docs unless the class can't be understood without them.

Keep `@param`, `@return`, and `@throws` text short. Explain the project contract, not the Java type or obvious
mechanics.

```java
/**
 * Builds the service endpoint URI from validated configuration.
 *
 * @param config validated preflight settings
 * @return service endpoint URI
 */
private static URI serviceUri(Config config) {
    ...
}
```

### Rule: document records as contracts

Trigger: a `record` groups validated settings, parsed inputs, or state passed across layers.

Do: add concise record Javadocs and `@param` tags when the fields are part of a project contract.

Do not: document records that only mirror a trivial local tuple, DTO, or test fixture with obvious fields.

### Rule: comment non-obvious steps; do not comment obvious ones

Add a comment above the step when any of these are true:

- The predicate or transform encodes a business rule not visible in the expression (authorization, compliance,
  soft-delete behavior, an upstream contract).
- The step works around a quirk of upstream data (legacy values, nulls that "shouldn't" exist, off-by-one units).
- Ordering matters and reordering would break correctness.
- A reducer's identity or combiner does more than it appears (`BigDecimal` scale, non-commutative combine logic, a
  mutating accumulator).

Do not add a comment when:

- It restates the predicate ("only active users", "map to DTO", "sum totals").
- The step is a plain field access or a single-arg method reference whose name already explains it.

Placement: one line above the step it describes. Explain why, not what.

```java
// Optional chain
return findUserId(request)
        .map(userRepository::find)
        // Exclude soft-deleted accounts; the repo still returns them for audit reasons.
        .filter(User::isActive)
        // Authorization: only return data when the requester owns the record or the record is unowned (legacy).
        .filter(user -> user.ownerId() == null || user.ownerId().equals(requesterId))
        .map(this::toDto)
        .orElse(null);
```

```java
// Stream chain
return orders.stream()
        // Drop cancelled orders before pricing; cancelled orders keep their line items for audit but must not bill.
        .filter(order -> order.status() != Status.CANCELLED)
        .flatMap(order -> order.lineItems().stream())
        // Tax-exempt items are flagged at the line level because of multi-jurisdiction orders.
        .filter(line -> !line.isTaxExempt())
        .map(LineItem::subtotal)
        // Identity uses scale=2 so the running total never silently loses cents from a higher-scale addend.
        .reduce(BigDecimal.ZERO.setScale(2, RoundingMode.HALF_UP), BigDecimal::add);
```

### Rule: never attribute code to a ticket, reviewer, or review pass

Trigger: writing or editing a comment (line comment or Javadoc) that describes why a piece of code exists.

Do: describe the invariant, business rule, upstream contract, or data quirk the code protects against. Present tense,
no author. Make the comment understandable to a reader who has never seen the ticket or the review.

Do not: name a ticket ID, a reviewer, a review tool, a review pass, or a review round in the comment. Do not preface
a comment with `// <TICKET-ID>:`, `// <TICKET-ID> pre-commit review:`, `// (<Reviewer name>):`,
`// (<Reviewer name> review):`, `// per <Reviewer name>'s review`, `// <Bot> PR#<N>:`, or any similar attribution. That
context belongs in the PR description, the commit message, and the code-review thread — it rots as the codebase
evolves and misleads a future reader who wasn't part of that review.

```java
// Do
// Legacy trials keep locationAccountEligibility unset when userLocationId is blank; fall back to accountEligibility.

// Do not
// BE-1234: Legacy trials keep locationAccountEligibility unset (per Mayank's review, PR #827).
```

Exception: this rule is about comments in the code. Ticket IDs and reviewer references remain welcome in commit
messages, PR descriptions, review threads, and any other artifact that lives outside the source tree.

## External calls and resources

### Rule: keep credentials out of URLs and command text

Trigger: building URLs, connection strings, client configuration, request text, or command arguments with secrets.

Do: pass usernames, passwords, tokens, and similar secrets through the API's supported credential mechanism.

Do not: concatenate passwords or tokens into URLs, command text, logs, or other strings unless the API has no
safer supported path.

### Rule: pass external values as data

Trigger: generated text, requests, queries, or command invocations include values from users, configuration,
environment variables, files, or external systems.

Do: use structured APIs, typed builders, argument arrays, or parameter binding so unusual values stay data.

Do not: concatenate external values into executable text or protocol strings when a structured API exists.

### Rule: close external resources with try-with-resources

Trigger: opening connections, clients, streams, files, sockets, or other closeable resources.

Do: use try-with-resources at the smallest useful scope.

Do not: rely on manual `close()` calls when the resource lifetime fits try-with-resources.

### Rule: make external-call timeouts explicit

Trigger: code connects to a database, network service, subprocess, or filesystem resource that may hang.

Do: set bounded timeouts at the call boundary; let the outer retry or orchestration layer control the total
budget.

Do not: allow one external call to consume the full job, request, or retry budget unless that is intentional and
documented.

## Streams and collection results

### Rule: default terminal collector is `Stream.toList()` (Java 16+)

Do: end pipelines with `.toList()` when the project runs on Java 16+ and callers do not mutate the result.

Why: modern idiom; returns an unmodifiable list.

```java
List<UserDto> dtos = users.stream()
        .filter(User::isActive)
        .map(this::toDto)
        .toList();
```

### Rule: use `Collectors.toCollection(ArrayList::new)` only when callers mutate

Trigger: downstream code calls `.add()`, `.remove()`, sorts in place, or otherwise mutates the list.

Do: collect explicitly into a mutable list.

Do not: use `Collectors.toList()` — its mutability is implementation-defined and not part of the API contract.

```java
List<UserDto> dtos = users.stream()
        .map(this::toDto)
        .collect(Collectors.toCollection(ArrayList::new));
```

### Rule: empty and literal lists

| Need                                   | Use                 |
|----------------------------------------|---------------------|
| Empty immutable                        | `List.of()`         |
| Small immutable literal                | `List.of(a, b, c)`  |
| Empty mutable (legacy API requires it) | `new ArrayList<>()` |

`Collections.emptyList()` is acceptable but predates `List.of()`. On Java 9+, prefer `List.of()`.

## Unit and magic-number conversions

### Rule: name conversion constants

Trigger: writing arithmetic that converts between units (time, currency, bytes, etc.).

Do: declare a named constant so the expression names both units.

Do not: inline literals like `1000L`, `100`, `1024`.

```java
private static final long MILLIS_PER_SECOND = 1000L;

long expiryMillis = record.getExpirySeconds() * MILLIS_PER_SECOND;
```

The constant name documents which side of the boundary uses which unit.
