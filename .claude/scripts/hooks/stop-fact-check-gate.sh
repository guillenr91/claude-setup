#!/usr/bin/env bash
set -euo pipefail

input="$(cat || true)"
hook_agent="${HOOK_AGENT:-}"

if [ -n "$input" ] && command -v jq >/dev/null 2>&1 && printf '%s' "$input" | jq empty >/dev/null 2>&1; then
  last_message="$(printf '%s' "$input" | jq -r '.. | objects | .last_assistant_message? // empty' | tail -n 1)"
  stop_hook_active="$(printf '%s' "$input" | jq -r 'if has("stop_hook_active") then (.stop_hook_active | tostring) else "" end')"
  event_name="$(printf '%s' "$input" | jq -r '.hook_event_name // ""')"
  session_key="$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .transcript_path // .transcriptPath // ""')"
else
  last_message=""
  stop_hook_active=""
  event_name=""
  session_key=""
fi

reason="Before final answer, validate, verify, and fact-check every claim and every piece of information in the final answer. Do not rely on assumptions, inference, guessing, training memory, or untested URLs. If any claim or piece of information cannot be verified to 100%, rewrite it with: I could not 100% fact-check this, so can't give you an accurate answer. To do so I would need to <specific steps>."

if [ "$hook_agent" = "claude" ] && [ "$stop_hook_active" = "false" ]; then
  jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
  exit 0
fi

if [ "$hook_agent" = "copilot" ] && [ -n "$session_key" ]; then
  marker_dir="${TMPDIR:-/tmp}/stop-fact-check-gate"
  marker_key="$(printf '%s' "$session_key" | cksum | awk '{print $1}')"
  marker_file="$marker_dir/$marker_key"
  mkdir -p "$marker_dir"
  if [ ! -f "$marker_file" ]; then
    printf '%s\n' "$session_key" > "$marker_file"
    jq -n --arg reason "$reason" '{decision: "block", reason: $reason}'
    exit 0
  fi
fi
