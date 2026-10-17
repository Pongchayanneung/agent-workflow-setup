#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# PreToolUse (file edits). Refuses to WIRE a hook script into settings.json / hooks.json
# unless that script's CURRENT content hash is recorded in ~/.agent-workflow/.smoketested
# (via hooks/smoketest.sh). Content-hash based, so editing a script after testing
# re-invalidates it (no name-based trust-on-first-use bypass).
# FAIL-OPEN: any parse error, or an edit not to settings.json, or one that adds no
# new hooks/*.sh reference -> allow. No lockout: editing other files and removing
# hook refs are never blocked; disable by editing THIS script (hooks/ not gated).
payload="$(cat)"
res="$(printf '%s' "$payload" | python3 -c '
import sys, json, os, re, hashlib
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    fp = ti.get("file_path","") or ti.get("path","")
    if not fp.endswith(("settings.json", "hooks.json")):
        print("ALLOW"); sys.exit(0)
    blob = " ".join(str(ti.get(k,"")) for k in ("content","new_string","new_str"))
    for e in (ti.get("edits") or []):
        blob += " " + str(e.get("new_string",""))
    refs = set(re.findall(r"hooks/([A-Za-z0-9_.-]+\.sh)", blob))
    if not refs:
        print("ALLOW"); sys.exit(0)
    tp = os.path.join(os.environ["AW"], ".smoketested")
    tested = set()
    if os.path.exists(tp):
        for line in open(tp):
            parts = line.split()
            if len(parts) >= 2:
                tested.add(parts[0])
    hd = os.path.join(os.environ["AW"], "hooks/")
    missing = []
    for r in refs:
        p = hd + r
        if os.path.exists(p):
            sha = hashlib.sha256(open(p,"rb").read()).hexdigest()
            if sha not in tested:
                missing.append(r)
    print("BLOCK:" + ",".join(sorted(missing)) if missing else "ALLOW")
except Exception:
    print("ALLOW")
' 2>/dev/null)"
case "$res" in
  BLOCK:*)
    echo "[SMOKE-TEST GATE] Hook(s) not smoke-tested at their current content: ${res#BLOCK:}" >&2
    echo "Run first:  bash ~/.agent-workflow/hooks/smoketest.sh ~/.agent-workflow/hooks/<name>.sh" >&2
    exit 2 ;;
  *) exit 0 ;;
esac
