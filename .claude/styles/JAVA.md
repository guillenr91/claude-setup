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
