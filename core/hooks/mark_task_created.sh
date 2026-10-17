#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# Claude hooks receive session_id on stdin. Never share state between sessions.
payload="$(cat)"
state_key="$(printf '%s' "$payload" | python3 -c 'import hashlib,json,sys
try:
 d=json.load(sys.stdin); sid=d.get("session_id")
 if isinstance(sid,str) and sid.strip(): print(hashlib.sha256(str(sid).encode()).hexdigest()[:24])
except (ValueError,AttributeError): pass' 2>/dev/null)"
[ -n "$state_key" ] || exit 0
HOOK_STATE="$AW/hook-state/$state_key"
mkdir -p "$HOOK_STATE" || exit 0
# PostToolUse (TaskCreate): session-local progress marker.
printf '1' > "$HOOK_STATE/.task_created"
exit 0
