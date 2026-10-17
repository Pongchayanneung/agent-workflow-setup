#!/usr/bin/env bash
# Adapter: run one shared hook script as an Antigravity (agy) PreToolUse/PostToolUse hook.
#   Usage:  bash agy-wrap.sh <script.sh> <PreToolUse|PostToolUse>
# agy sends its own payload ({conversationId, toolCall:{name,args}, workspacePaths, ...}) and reads a
# decision back as {"decision":"deny","reason":"..."} on stdout. The shared scripts expect the
# Claude-style payload (session_id, tool_name, tool_input.file_path/command) and block with exit 2.
# This wrapper translates both ways. Plain-text stdout from the script is dropped (agy's
# Pre/PostToolUse hooks have no documented context channel).
AW="${AGENT_WORKFLOW_HOME:-$(cd "$(dirname "$0")/.." && pwd)}"; export AGENT_WORKFLOW_HOME="$AW"   # wrapper lives in $AW/hooks
script="$AW/hooks/$(basename "${1:?usage: agy-wrap.sh <script.sh> <event>}")"
[ -f "$script" ] || { echo "agy-wrap: no such hook $script" >&2; exit 1; }
payload="$(cat)"
translated="$(printf '%s' "$payload" | EVENT="${2:-PreToolUse}" python3 -c '
import json, os, sys
try:
    d = json.load(sys.stdin)
except ValueError:
    sys.exit(1)
tc = d.get("toolCall") or {}
a = tc.get("args") or {}
ti = dict(a)
for k in ("TargetFile", "AbsolutePath", "FilePath", "File", "Path"):
    if isinstance(a.get(k), str):
        ti["file_path"] = a[k]; break
if isinstance(a.get("CommandLine"), str):
    ti["command"] = a["CommandLine"]
# content: the known write arg, else every string arg joined (covers edit tools whose arg names we have not seen)
ti["content"] = a.get("CodeContent") or "\n".join(v for v in a.values() if isinstance(v, str))
ws = d.get("workspacePaths") or [""]
print(json.dumps({"session_id": d.get("conversationId", ""), "hook_event_name": os.environ["EVENT"],
                  "cwd": ws[0], "transcript_path": d.get("transcriptPath", ""),
                  "tool_name": tc.get("name", ""), "tool_input": ti}))
')" || exit 0     # unparseable payload: fail open
err="$(mktemp)"; trap 'rm -f "$err"' EXIT
printf '%s' "$translated" | bash "$script" >/dev/null 2>"$err"; rc=$?
if [ "$rc" -eq 2 ]; then
  REASON="$(cat "$err")" python3 -c 'import os, json; print(json.dumps({"decision": "deny", "reason": os.environ["REASON"]}))'
fi
exit 0
