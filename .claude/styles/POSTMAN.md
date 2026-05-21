# Postman Style Guide

Use these rules when generating or reviewing Postman collections, requests, environments, and scripts. Apply a rule only
when its trigger matches. Prefer existing collection conventions when they are more specific.

## Collection structure

### Rule: group by purpose, not by URL path

**Do:** organize folders by service or domain, then by interaction type: health, reads, writes, admin, or support.

**Do not:** create folders that mirror the URL path verbatim.

**Why:** URLs already show the path. Folder names should show intent.

```
Collection
└── <Service or domain>
    ├── Health / status
    ├── Reads (GET)
    ├── Writes (POST / PUT / PATCH / DELETE)
    └── Admin / support
```

## Environment variables

### Rule: use `camelCase`, name by meaning

**Do:** `baseUrl`, `authUrl`, `apiKey`, `accessToken`, `currentUserId`, `tenantId`.

**Do not:** encode the type in the name (`apiKeyString`, `userIdInt`).

### Rule: every value used in more than one request lives in the environment

**Trigger:** the same value (URL, ID, token) appears in two or more requests.

**Do:** define an environment variable and reference it via `{{name}}`.

**Do not:** hardcode the value per request.

### Rule: every environment defines at least these variables

- `baseUrl` — primary API base URL.
- An auth credential (`apiKey` or `accessToken`).
- An identity variable that scopes most requests (e.g. `currentUserId`, `tenantId`).

### Rule: secrets are marked secret and never committed with real values

**Do:**
- Mark credentials (`apiKey`, `accessToken`, anything bearer-shaped) as **secret** in Postman.
- Commit `*.template.json` environment files with placeholder values only.

**Do not:** commit environment files that contain real credentials.

### Rule: extract response values needed by later requests

**Trigger:** a response contains a value that a subsequent request will need.

**Do:** set the variable in the test script. Keep extraction small.

**Do not:** parse deeply nested structures or add long conditionals. Split the request or move shared logic to a
collection-level script instead.

```javascript
const data = pm.response.json();

if (data?.id) {
    pm.environment.set("currentResourceId", data.id);
}
```

## Request descriptions

### Rule: every request has a description with these sections in order

1. **What it does**: one sentence.
2. **Preconditions**: auth, prior requests, and required data.
3. **Body fields**: for `POST`, `PUT`, and `PATCH`, list each field and whether it is required.
4. **Successful response**: status code and key fields the caller can rely on.
5. **Failure modes**: non-obvious error conditions.

**Do not:** write descriptions that just restate the URL or HTTP method.

```markdown
Create a subscription for the current user.

Preconditions:
- User is authenticated (apiKey set).
- User has no active subscription on the target plan.

Body fields:
- planCode (required): plan identifier.
- startsAt (optional, ISO-8601): defaults to now.

Success: 201 with the new subscription object, including its id.

Errors:
- 409 if the user already has an active subscription on this plan.
```

## Test scripts

### Rule: assert response shape, not just status

**Do:** include at least one response-shape assertion alongside any status check.

**Do not:** rely on `pm.response.to.have.status(200)` alone. A 200 response with a malformed body is still broken.

```javascript
pm.test("Status is 200", () => pm.response.to.have.status(200));

pm.test("Response has expected shape", () => {
    const data = pm.response.json();
    pm.expect(data).to.have.property("id");
    pm.expect(data.items).to.be.an("array");
});
```

### Rule: failure must be loud

**Trigger:** a request is expected to populate an environment variable.

**Do:** fail the test if the source data is missing.

**Do not:** silently skip setting the variable. That creates later failures far from the cause.

```javascript
const data = pm.response.json();

pm.test("Response contains data", () => {
    pm.expect(data?.items, "items array").to.be.an("array").that.is.not.empty;
});

if (data?.items?.length) {
    pm.environment.set("firstItemId", data.items[0].id);
}
```

### Rule: cap script size

**Trigger:** test or pre-request script exceeds ~30 lines.

**Do:** split the request, or move shared logic to a collection-level pre-request or test script.

## URLs

### Rule: parameterize anything that varies between environments or runs

**Do:** use `{{variable}}` for IDs, hostnames, and tokens.

**Do not:** hardcode IDs, even "stable" test IDs — they change between environments.

```
{{baseUrl}}/v1/users/{{currentUserId}}/subscriptions
```

### Rule: query parameters live in the URL object's `query` array

**Do:** define each query parameter as an entry in `query`.

**Do not:** embed query parameters only in the raw URL string. They become invisible in the Postman UI and cannot be
toggled.

```json
{
  "url": {
    "raw": "{{baseUrl}}/v1/users?status=active&limit=50",
    "query": [
      { "key": "status", "value": "active" },
      { "key": "limit",  "value": "50" }
    ]
  }
}
```

## Headers

### Rule: standard headers for an authenticated JSON API

```json
[
  { "key": "Authorization", "value": "Bearer {{accessToken}}" },
  { "key": "Content-Type",  "value": "application/json" },
  { "key": "Accept",        "value": "application/json" }
]
```

### Rule: custom auth schemes are documented at the collection level

**Trigger:** the API uses `ApiKey`, `X-Api-Key`, `X-Forwarded-User`, or any non-standard auth header.

**Do:** document the scheme once on the collection, and reference an environment variable in each request.

**Do not:** embed credential values per request.

## Pre-commit verification

### Rule: a request is not done until it has run and one assertion has failed once

**Before adding a request to the collection:**

1. Run it against a real environment; confirm a successful response.
2. Mutate one assertion temporarily to confirm it can fail.
3. Note any external dependencies (upstream services, seeded data) in the description.

**Why:** an assertion that has never been observed failing is documentation, not a test.
