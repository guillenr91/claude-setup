# Java Style Guide

Directive rules for generating and reviewing Java code. Each rule has a trigger, an action, and — where relevant — a rationale that lets you adjudicate edge cases.

## Null handling

### Rule: prefer `Optional` chaining over cascading null checks

**Trigger:** a method threads a value through two or more sequential nullable lookups, transformations, or filters.

**Do:** express the flow as one `Optional` chain.

**Do not:** write `if (x == null) return ...;` guards in series.

**Exceptions (write the imperative form instead):**
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

### Rule: helpers return `Optional<T>`, not `null`

**Trigger:** writing or modifying a helper that performs extraction or lookup and may have no result.

**Do:** declare the return type as `Optional<T>`.

**Exception:** public API methods whose `null` semantics are already established by an external contract (framework, downstream service, persisted schema). Do not change those without coordination.

### Rule: terminate the chain only at a non-`Optional` boundary

**Do:**
- Return `Optional<T>` from helpers so callers can keep chaining.
- Use `.orElse(...)` / `.orElseThrow(...)` / `.orElseGet(...)` only in methods whose return type is fixed and non-`Optional`.

**Do not:** end a helper's chain with `.orElse(null)` and force every caller to re-wrap with `Optional.ofNullable(...)`.

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

## Comments on fluent pipelines

Applies to any fluent pipeline: `Optional` chains and `Stream` chains (`.filter`, `.map`, `.flatMap`, `.reduce`, `.collect`, `.sorted`, `.takeWhile`, etc.).

### Rule: comment non-obvious steps; do not comment obvious ones

**Add a comment above the step when any of these are true:**
- The predicate or transform encodes a business rule not visible in the expression (authorization, compliance, soft-delete semantics, upstream-contract requirements).
- The step works around a quirk of upstream data (legacy values, nulls that "shouldn't" exist, off-by-one units).
- Ordering matters and reordering would break correctness.
- A reducer's identity or combiner does more than it appears (`BigDecimal` with a specific scale, non-commutative combine, accumulator that mutates).

**Do not add a comment when:**
- It restates the predicate ("only active users", "map to DTO", "sum totals").
- The step is a plain field access or a single-arg method reference whose name already explains it.

**Comment placement:** one line above the step it describes. Explain *why*, not *what*.

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

## Streams and collection results

### Rule: default terminal collector is `Stream.toList()` (Java 16+)

**Do:** end pipelines with `.toList()`.

**Why:** unmodifiable, null-safe, modern idiom.

```java
List<UserDto> dtos = users.stream()
        .filter(User::isActive)
        .map(this::toDto)
        .toList();
```

### Rule: use `Collectors.toCollection(ArrayList::new)` only when callers mutate

**Trigger:** downstream code calls `.add()`, `.remove()`, sorts in place, or otherwise mutates the list.

**Do:** collect explicitly into a mutable list.

**Do not:** use `Collectors.toList()` — its mutability is implementation-defined and not part of the API contract.

```java
List<UserDto> dtos = users.stream()
        .map(this::toDto)
        .collect(Collectors.toCollection(ArrayList::new));
```

### Rule: empty and literal lists

| Need                                   | Use                  |
|----------------------------------------|----------------------|
| Empty immutable                        | `List.of()`          |
| Small immutable literal                | `List.of(a, b, c)`   |
| Empty mutable (legacy API requires it) | `new ArrayList<>()`  |

`Collections.emptyList()` is acceptable but predates `List.of()`. On Java 9+, prefer `List.of()`.

## Unit and magic-number conversions

### Rule: name conversion constants

**Trigger:** writing arithmetic that converts between units (time, currency, bytes, etc.).

**Do:** declare a named constant. The expression should read like English.

**Do not:** inline literals like `1000L`, `100`, `1024`.

```java
private static final long MILLIS_PER_SECOND = 1000L;

long expiryMillis = record.getExpirySeconds() * MILLIS_PER_SECOND;
```

The constant name documents which side of the boundary uses which unit — usually more important than the number.
