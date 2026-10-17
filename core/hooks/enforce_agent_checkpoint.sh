#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# PreToolUse (Agent). Blocks spawning a BACKGROUND agent whose prompt lacks a
# checkpoint-to-disk directive, so a long agent can't lose work to a mid-run crash.
# FAIL-OPEN: parse error or non-background agent -> allow. Only gates run_in_background.
payload="$(cat)"
res="$(printf '%s' "$payload" | python3 -c '
import sys, json, re
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    if not ti.get("run_in_background"):
        print("ALLOW"); sys.exit(0)
    prompt = (ti.get("prompt") or "").lower()
    pat = r"checkpoint|incrementally|(write|save|append|dump|log)[^.\n]{0,30}(findings|results|progress|output|report|inventory)[^.\n]{0,30}(to|into)[^.\n]{0,15}file|(to|into)[^.\n]{0,15}(a )?file[^.\n]{0,20}(as you go|incrementally)"
    print("ALLOW" if re.search(pat, prompt) else "BLOCK")
except Exception:
    print("ALLOW")
' 2>/dev/null)"
if [ "$res" = "BLOCK" ]; then
  echo "[CHECKPOINT GATE] A background agent must be told to write its findings to a file AS IT GOES (not only return at the end), so a mid-response crash can't lose the work. Add a directive like: 'Write your findings to <path> incrementally as you work.'" >&2
  exit 2
fi
exit 0
