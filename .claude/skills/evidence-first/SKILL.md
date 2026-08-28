---
name: evidence-first
description: >-
  Enforces evidence-first verification of every factual claim before it is sent
  to the operator. Read/grep/run the code, docs, or command that would confirm
  or refute each claim; state only what you can cite this session. No
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

Loaded into context when invoked. Keep concise, explicit, and actionable for AI agents. No decorative formatting
around prose (no `**bold**`, `*italic*`, `_italic_`, `> blockquote`). Preserve these standards in every future edit.

Prevents inference, guessing, pattern-matching, model recall, and prior-session memory from being stated as fact.
Every factual claim in every reply — substantive, conversational, status, single-line — must be backed by
in-session evidence (read, grep, run, fetch) or flagged with the operator's exact uncertainty phrasing from the
global agent instruction file (`CLAUDE.md` / `AGENTS.md`). There are no exceptions and no size threshold.

## Rule 1 — enumerate every factual claim before drafting

Before writing the reply, list every factual claim it will contain. A factual claim is any statement about what
code does, what a tool or command returns, what a file contains, what a doc/page says, what happened earlier in
the session, what a system did, or what state exists somewhere.

No claim is exempt from verification. Load-bearing claims (if wrong, the conclusion is wrong) still require the
deepest evidence; the distinction is about how much you verify, never about whether.

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

If a claim cannot be verified this session, do not state it as fact. Use the exact uncertainty phrasing from the
operator's global agent instruction file (`CLAUDE.md` / `AGENTS.md`):
"The following information has not been validated, 100% verified, nor fact-checked: <item>. To validate it I would
need to <steps>."

## Rule 3 — attach evidence inline in the reply

Every factual claim must ship with its evidence in the same reply. The operator must be able to audit the
verification without opening another tool.

- Code claims: cite `path:line` AND quote the relevant snippet (≤5 lines) or paste a targeted grep output.
- Command claims: paste the exact command and its output. Trim long output but do not summarize the fact away.
- Doc/URL claims: quote the sentence(s) that support the claim from a page fetched this session, and include the
  URL you fetched.
- Conversation claims: quote the earlier turn verbatim.
- Tool-result claims: quote the relevant fragment of the tool result.

A summary that requires trusting the summary is not evidence. If the operator cannot verify the claim from the
reply alone, the evidence is not attached — go attach it before sending.

## Rule 4 — do not carry premises across drafts

When re-drafting after operator pushback, discard the disputed premise and re-open the source. Do not build draft
N+1 on the same untested premise as draft N. Each new draft starts from re-verified evidence.

If the operator challenges "X is true", the next tool call must be reading the source that would confirm or
refute X — not producing a new phrasing of the same claim.

## Rule 5 — when the operator asks "are you sure?" / "have you verified?"

Re-verify the specific claim they are questioning, not adjacent facts. Verifying a line number for the fifth time
while the actual behavior claim remains unread is not verification.

1. Identify the specific claim the operator is questioning. Quote it back if there is any ambiguity.
2. Open the exact source that would falsify or confirm it — the code that runs the behavior, the doc fetched this
   session, the command output. Not related code, not the caller, not the test that exercises it, unless one of
   those IS the load-bearing source.
3. Report what you saw. Quote the snippet or command output inline.
4. If the fresh evidence contradicts the prior claim, retract the prior claim explicitly ("I was wrong: <what the
   evidence actually shows>") before continuing.

## Rule 6 — pre-send checklist

Before sending the reply, walk this checklist. If any answer is no, the reply is not ready.

1. Have I enumerated every factual claim in the reply?
2. For each, have I read/run/fetched the source in this session?
3. Is the evidence attached inline so the operator can audit it without another tool call?
4. Have I flagged any claim I could not verify with the exact uncertainty phrasing from the operator's global
   agent instruction file?
5. Have I separated verified facts from judgment ("my read" / "I'd recommend" / "opinion:")?
6. Am I about to use any of the banned hedges below in place of verification?

Banned in place of verification: "probably", "likely", "should work", "I think", "must be", "usually", "typically",
"in most cases", "the pattern is", "it looks like", "seems to", "appears to", "I believe". These are guesses
dressed as claims. Either verify and state plainly with evidence attached, or use the exact uncertainty phrasing
from Rule 2. Judgment phrases ("my read", "I'd recommend") are allowed only for clearly-labeled opinions, never
for factual claims.

## Rule 7 — reporting structure

Structure every reply so the operator can audit verification at a glance:

- Facts verified this session — cite `path:line` or command output with inline snippet/quote.
- Facts not verifiable this session — use the exact uncertainty phrasing from the operator's global agent
  instruction file.
- Judgment and opinions — mark with "my read", "I'd recommend", "opinion:".

Do not mix categories inside a single sentence. A sentence that reads as a fact must be a verified fact with
evidence attached.

## Cost model

Reading a method body is 1 tool call. Fetching a doc is 1 tool call. Running a command is 1 tool call. Posting a
wrong claim costs a retraction, a re-draft, operator trust, and — for PR review comments — reviewer trust and
potentially a revert. When verification takes fewer than 3 tool calls, always verify. When verification is
impossible this session, use the uncertainty phrasing; never bridge the gap with a hedge word.

## Anti-patterns to catch in yourself

- "This probably works like X because the surrounding structure looks like Y" — stop, read X.
- "The legacy code must have done Z since Z is what the docs describe" — stop, blame + read.
- "The operator asked me to verify, so I re-ran the grep that found the line number" — that is not what they
  asked. Re-verify the behavior claim, not the line-number claim.
- "Three drafts in and the operator is still pushing back" — go back to the source. The next draft is not the fix.
- "I'll add a hedge word so I don't have to verify" — hedges are not verification. Verify or use the exact
  uncertainty phrasing.
- "I remember this from a prior session" — prior-session memory is not in-session evidence. Re-read the source.
- "The tool/skill description said X, so X is guaranteed" — descriptions can drift from implementation. If X is
  load-bearing, verify by running the tool or reading the source.
- "It's just a short reply, verification is overkill" — the size of the reply does not change the verification
  bar. Every factual claim gets evidence.
