---
name: evidence-first
description: >-
  Enforces evidence-first verification of every factual claim before it is sent
  to the operator. Read/grep/run the code, docs, or command that would confirm
  or refute each claim, unless a reusable evidence record has a matching
  source fingerprint checked this session; state only what you can cite. No
  inference, guessing, pattern-matching, model recall, or prior-session memory
  is allowed to be stated as fact. Applies to ALL replies that make factual
  claims — research findings, PR review replies, technical conclusions, status
  updates, single-line answers, re-drafts after operator pushback, and short
  claims like "this is legacy behavior" / "already handled" / "not a
  regression" / "should work" / "the pattern is". Re-invoke when the operator
  asks "are you sure?" / "have you verified?" / pushes back on a claim. Skip
  only for pure meta or conversational replies with no factual content, pure
  opinion clearly labeled as such, recaps of what the operator just said, and
  read-only lookups whose output is shown to the operator in the same turn.
---

# Evidence First Skill

Loaded into context when invoked. Keep brief and concise, explicit, and actionable for AI agents. Preserve every concrete instruction and action; cut verbose prose. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Prevents inference, guessing, pattern-matching, model recall, and prior-session memory from being stated as fact. Every factual claim in every reply — substantive, conversational, status, single-line — must be backed by direct in-session evidence or a reusable evidence record whose source fingerprint matches in this session, or flagged with the operator's exact uncertainty phrasing from the global agent instruction file (`CLAUDE.md` / `AGENTS.md`). No exceptions, no size threshold.

## Rule 1 — enumerate every factual claim before drafting

Before writing the reply, list every factual claim. A factual claim is any statement about what code does, what a tool or command returns, what a file contains, what a doc/page says, what happened earlier in the session, what a system did, or what state exists somewhere.

No claim is exempt. Load-bearing claims (if wrong, the conclusion is wrong) require the deepest evidence; the distinction is about how much, never whether.

Do not treat any of the following as verification:

- File paths and line numbers of code whose body you have not read this session.
- Git blame dates on lines whose behavior you have not read this session.
- Test names whose assertions you have not opened this session.
- The shape of a similar-looking method elsewhere in the codebase.
- What "usually" or "typically" happens with this library, framework, or tool.
- Model recall from prior sessions, training data, or general knowledge.
- Prior turns in this session where the underlying source was never opened.
- Tool or skill descriptions when the claim is about actual behavior (descriptions can drift from implementation).

## Rule 2 — verify each claim by direct evidence

Match the method to the claim type. Reasoning about code shape is not a substitute.

| Claim type                                | Verification                                                     |
|-------------------------------------------|------------------------------------------------------------------|
| "This method does X"                      | Read the method body. Names lie; bodies do not.                  |
| "Legacy did Y" / "always was Z"           | `git blame` on the load-bearing lines + read the file there.     |
| "The other endpoint/caller does Z"        | Open that endpoint or caller. Do not extrapolate from this one.  |
| "Pattern P applies here"                  | Read here. Similarity to another site is not evidence.           |
| "This test locks the behavior"            | Open the test. Read the assertion.                               |
| "Not a regression" / "already handled"    | Read pre-PR behavior at the specific site (`git show` / blame).  |
| "Everything else does X too"              | Grep and read a sample. "It's a pattern" without a sample = no.  |
| "The command outputs Q"                   | Run it this session and capture the output.                      |
| "The doc says D" / "The API returns R"    | Fetch the doc/endpoint this session and quote D or paste R.      |
| "Earlier in this session we did E"        | Scroll and quote the earlier turn. Do not reconstruct.           |
| "The library/version supports F"          | Fetch current docs or read the installed source; do not recall.  |

If a claim cannot be verified this session, do not state it as fact. Use the exact uncertainty phrasing from the operator's global agent instruction file (`CLAUDE.md` / `AGENTS.md`):
"The following information has not been validated, 100% verified, nor fact-checked: <item>. To validate it I would need to <steps>."

## Rule 2A — reusable evidence records

Resolve the evidence directory before direct verification:

- Active ticket named by the user or already loaded into context: `.claude/context/tickets/<TICKET_ID>/evidence/`.
- No active ticket: `.claude/evidence/`.

Do not infer a ticket ID solely to choose a directory. Search only the resolved directory for a record matching the exact claim or source. Read `.claude/evidence/CLAUDE.md` before creating or editing project-level records; this skill defines the ticket-level record format.

Reuse a record only when all of the following are present:

- One exact claim, its source, concise direct proof, a deterministic fingerprint command, its expected output, and the verification date.
- A fresh run of the stored fingerprint command in this session with output exactly matching the record.
- A source whose matching fingerprint proves the claim's evidence remains applicable.

When all conditions pass, reuse the stored proof and attach it with the fresh fingerprint output. Skip the underlying direct verification. When any condition fails, re-verify directly, then create or update the record if the claim is eligible.

Store one eligible atomic claim per `<evidence-dir>/<claim-id>.md`. Create or update the record immediately after direct verification. Eligible claims are static file, versioned artifact, or immutable-document facts with a deterministic fingerprint. Do not reuse records for command or test results, runtime behavior, environment state, credentials, deployments, mutable URLs, or any claim without a fingerprint that proves continued applicability. Never record secrets, tokens, personal data, or unredacted credentials.

Optimize every record for context: use only the template fields, no title, headings, analysis, duplicated source text, or filler. Keep `claim` atomic and `proof` to 40 words or five code lines maximum.

## Record template

```markdown
---
claim: <one atomic fact>
source: <repo-relative path or immutable URL>
check: <deterministic fingerprint command>
expected: <exact fingerprint output>
verified: YYYY-MM-DD
proof: <≤40 words or ≤5 code lines; redact sensitive values>
---
```

## Rule 3 — attach evidence inline in the reply

Every factual claim ships with its evidence in the same reply. The operator must be able to audit without opening another tool.

- Code claims: cite `path:line` AND quote the relevant snippet (≤5 lines) or paste a targeted grep output.
- Command claims: paste the exact command and its output. Trim long output but do not summarize the fact away.
- Doc/URL claims: quote the sentence(s) supporting the claim from a page fetched this session, include the URL.
- Conversation claims: quote the earlier turn verbatim.
- Tool-result claims: quote the relevant fragment.
- Reused-record claims: quote the stored proof and the fresh fingerprint command output that matched it.

A summary that requires trusting the summary is not evidence. If the operator cannot verify from the reply alone, the evidence is not attached — attach it before sending.

## Rule 4 — do not carry premises across drafts

When re-drafting after operator pushback, discard the disputed premise and re-open the source. Do not reuse a record for the disputed claim. Do not build draft N+1 on the same untested premise as draft N. Each new draft starts from direct re-verified evidence.

If the operator challenges "X is true", the next tool call must be reading the source that would confirm or refute X — not producing a new phrasing of the same claim.

## Rule 5 — when the operator asks "are you sure?" / "have you verified?"

Re-verify the specific claim being questioned, not adjacent facts. Verifying a line number for the fifth time while the actual behavior claim remains unread is not verification.

1. Identify the specific claim the operator is questioning. Quote it back if ambiguous.
2. Open the exact source that would falsify or confirm it — the code that runs the behavior, the doc fetched this session, the command output. Not related code, not the caller, not the test that exercises it, unless one of those IS the load-bearing source.
3. Report what you saw. Quote the snippet or command output inline.
4. If fresh evidence contradicts the prior claim, retract explicitly ("I was wrong: <what the evidence actually shows>") before continuing.

## Rule 6 — pre-send checklist

Before sending, walk this checklist. If any answer is no, the reply is not ready.

1. Have I enumerated every factual claim in the reply?
2. For each, have I directly verified the source in this session, or reused a record with a fresh exact fingerprint match?
3. Is the evidence attached inline so the operator can audit it without another tool call?
4. Have I flagged any claim I could not verify with the exact uncertainty phrasing?
5. Have I separated verified facts from judgment ("my read" / "I'd recommend" / "opinion:")?
6. For every reused record, did I run its fingerprint command this session and confirm an exact match?
7. Am I about to use any banned hedge below in place of verification?

Banned in place of verification: "probably", "likely", "should work", "I think", "must be", "usually", "typically", "in most cases", "the pattern is", "it looks like", "seems to", "appears to", "I believe". These are guesses dressed as claims. Either verify and state plainly with evidence attached, or use the exact uncertainty phrasing from Rule 2. Judgment phrases ("my read", "I'd recommend") are allowed only for clearly-labeled opinions, never for factual claims.

## Rule 7 — reporting structure

Structure every reply so the operator can audit verification at a glance:

- Facts verified this session — cite direct evidence, or a reused record with its fresh matching fingerprint output.
- Facts not verifiable this session — use the exact uncertainty phrasing from the global agent instruction file.
- Judgment and opinions — mark with "my read", "I'd recommend", "opinion:".

Do not mix categories inside a single sentence. A sentence that reads as a fact must be a verified fact with evidence attached.

## Cost model

Reading a method body is 1 tool call. Fetching a doc is 1 tool call. Running a command is 1 tool call. A matching reusable record replaces repeated direct verification with one fingerprint check. Posting a wrong claim costs a retraction, a re-draft, operator trust, and — for PR review comments — reviewer trust and potentially a revert. When verification takes fewer than 3 tool calls, always verify. When impossible, use the uncertainty phrasing; never bridge the gap with a hedge word.

## Anti-patterns to catch in yourself

- "This probably works like X because the surrounding structure looks like Y" — stop, read X.
- "The legacy code must have done Z since Z is what the docs describe" — stop, blame + read.
- "The operator asked me to verify, so I re-ran the grep that found the line number" — not what they asked. Re-verify the behavior claim, not the line-number claim.
- "Three drafts in and the operator is still pushing back" — go back to the source. The next draft is not the fix.
- "I'll add a hedge word so I don't have to verify" — hedges are not verification. Verify or use the uncertainty phrasing.
- "I remember this from a prior session" — prior-session memory is not in-session evidence. Re-read the source.
- "The evidence record exists, so the source is still valid" — run the stored fingerprint command and require an exact match.
- "The test passed before, so I can reuse the result" — runtime results are not reusable records. Run the test again.
- "The tool/skill description said X, so X is guaranteed" — descriptions can drift from implementation. If X is load-bearing, verify by running the tool or reading the source.
- "It's just a short reply, verification is overkill" — reply size does not change the verification bar. Every factual claim gets evidence.
