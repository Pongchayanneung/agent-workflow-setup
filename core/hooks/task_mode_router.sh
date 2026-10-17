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
# UserPromptSubmit: mode persists within this session; reset review notice per turn.
flag="$HOOK_STATE/.task_mode"
rm -f "$HOOK_STATE/.review_nudged" "$HOOK_STATE/.task_created" "$HOOK_STATE/.ctx_nudged"
current="light"
[ -f "$flag" ] && current="$(tr -d '[:space:]' < "$flag")"
case "$current" in light|full|block) ;; *) current="light" ;; esac
prompt="$(printf '%s' "$payload" | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("prompt", ""))
except (ValueError,AttributeError): pass' 2>/dev/null)"
new="$current"
shopt -s nocasematch
if [[ "$prompt" =~ /mode-block|lock[[:space:]]*down|strict[[:space:]]+mode ]]; then
  new="block"
elif [[ "$prompt" =~ /mode-full|big[[:space:]]+task|complex[[:space:]]+task|important[[:space:]]+task|critical[[:space:]]+task|major[[:space:]]+refactor|prod(uction)?[[:space:]]+deploy ]]; then
  new="full"
elif [[ "$prompt" =~ /mode-light|small[[:space:]]+task|trivial[[:space:]]+task|quick[[:space:]]+fix ]]; then
  new="light"
fi
shopt -u nocasematch
printf '%s' "$new" > "$flag"
case "$new" in
  light) echo "TASK MODE: light. Show refined scope only when unclear or complex. Follow your global AGENTS.md rules for routing and proportional checks." ;;
  full) echo "TASK MODE: full. Follow your global AGENTS.md rules; plan, review and verify according to the actual change and risk." ;;
  block) echo "TASK MODE: block. Follow your global AGENTS.md rules; honor outward/destructive-action approvals and verify recovery before risky changes." ;;
esac
echo 'SKILL CHECK: read the request by intent, not keywords. Before acting, name the matching skill from the list, or write "skill: none". Prefer the narrower skill when two overlap.'
exit 0
