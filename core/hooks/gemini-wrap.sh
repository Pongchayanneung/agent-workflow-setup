#!/usr/bin/env bash
# Adapter: run one of the shared hook scripts as a Gemini CLI / Antigravity-style hook.
#   Usage in settings.json:  bash "$HOME/.agent-workflow/hooks/gemini-wrap.sh" warm_resume.sh
# Gemini wants stdout to be ONE JSON object. The shared scripts print plain text (that is how
# Claude Code turns stdout into context). This wrapper runs the script on the same stdin payload,
# then re-wraps its stdout as hookSpecificOutput.additionalContext. Exit code 2 (a block) and its
# stderr pass straight through. Anything else the script prints to stderr is kept as a warning.
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"
script="$AW/hooks/$(basename "${1:?usage: gemini-wrap.sh <script.sh>}")"
[ -f "$script" ] || { echo "gemini-wrap: no such hook $script" >&2; exit 1; }
payload="$(cat)"
err="$(mktemp)"; trap 'rm -f "$err"' EXIT
out="$(printf '%s' "$payload" | bash "$script" 2>"$err")"; rc=$?
cat "$err" >&2
[ "$rc" -eq 2 ] && exit 2
event="$(printf '%s' "$payload" | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("hook_event_name",""))
except ValueError: print("")')"
OUT="$out" EVENT="$event" python3 -c 'import os,json
o=os.environ["OUT"]
print(json.dumps({"hookSpecificOutput":{"hookEventName":os.environ["EVENT"],"additionalContext":o}} if o.strip() else {}))'
exit 0
