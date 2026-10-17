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
# PostToolUse: risk-based escalation and at most one review notice per turn.
flag="$HOOK_STATE/.task_mode"
mode="light"
[ -f "$flag" ] && mode="$(tr -d '[:space:]' < "$flag")"
case "$mode" in light|full|block) ;; *) mode="light" ;; esac
tool="$(printf '%s' "$payload" | python3 -c 'import sys,json
try: print(json.load(sys.stdin).get("tool_name", ""))
except (ValueError,AttributeError): pass' 2>/dev/null)"
case "$tool" in Edit|Write|MultiEdit) ;; *) exit 0 ;; esac
# Resolve relative paths against the payload cwd.
fpath="$(printf '%s' "$payload" | python3 -c 'import sys,json,os
try:
 d=json.load(sys.stdin); ti=d.get("tool_input") or {}
 paths=[ti.get("file_path") or ti.get("path") or ""]
 for p in paths:
  if p: print(os.path.normpath(os.path.join(d.get("cwd") or os.getcwd(),p)))
except (ValueError,AttributeError,TypeError): pass' 2>/dev/null)"
sensitive_re='/\.(claude|codex|gemini)/(settings|hooks)|/\.agent-workflow/hooks/|/(CLAUDE|AGENTS|GEMINI)\.md$|/\.zshrc$|/\.bashrc$|/\.zprofile$'
notice=""
if printf '%s' "$fpath" | grep -Eq "$sensitive_re" && [ "$mode" = "light" ]; then
  printf 'full' > "$flag"
  mode="full"
  notice="[AUTO-ESCALATE light->full: sensitive configuration edited]"
fi
if { [ "$mode" = "full" ] || [ "$mode" = "block" ]; } && [ ! -f "$HOOK_STATE/.review_nudged" ]; then
  printf '1' > "$HOOK_STATE/.review_nudged"
  echo "${notice:-[MODE=$mode]} Review the change and run relevant checks before declaring done. Follow your global AGENTS.md rules; sensitive hook/config changes need a fixture smoke check."
fi
exit 0
