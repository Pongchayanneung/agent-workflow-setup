#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# PreToolUse (Write, Bash). Speed bump before CREATING a new script under ~/bin or
# ~/.agent-workflow/tools: shows what the capability registry already has, so existing tools get
# reused instead of rebuilt.
#
# Covers BOTH creation paths. Watching only Write left an obvious hole: a heredoc, cp, mv,
# tee or curl -o through the Bash tool is how an agent most naturally writes a script, and
# it walked straight past the gate.
#
# Deliberately a speed bump, not a wall. Creating new tools is legitimate; forgetting to
# check is the actual failure mode. The first attempt at a given target path is blocked and
# shows candidates; the path is recorded in ~/.agent-workflow/.cap-ack so an immediate retry proceeds.
#
# FAIL-OPEN everywhere: parse error, missing registry, an existing file, a relative path, or
# a target outside the two watched dirs -> allow. Never blocks edits, only first-time creation.
payload="$(cat)"
res="$(printf '%s' "$payload" | python3 -c '
import sys, json, os, re

def targets_from_write(ti):
    fp = ti.get("file_path", "") or ti.get("path", "")
    return [fp] if fp else []

def targets_from_bash(ti):
    # A path only counts as a creation TARGET when it sits directly after a write operator.
    # Merely mentioning a path (ls, rm, grep, cat) must not trip the gate.
    cmd = ti.get("command", "") or ""
    home = os.path.expanduser("~")
    P = r"(?:~|\$HOME|" + re.escape(home) + r")/[\w./-]+\.(?:sh|py|mjs|js)"
    pats = [
        r">>?\s*(" + P + r")",                       # cat > path / echo >> path
        r"\btee\s+(?:-\S+\s+)*(" + P + r")",         # tee [-a] path
        r"\btouch\s+(?:-\S+\s+)*(" + P + r")",
        r"-o\s+(" + P + r")",                        # curl -o path
        r"\b(?:cp|mv|install)\s+[^;&|\n]*?\s(" + P + r")(?:\s|$|;|&|\|)",   # last arg
    ]
    out = []
    for pat in pats:
        for m in re.finditer(pat, cmd):
            out.append(os.path.expanduser(m.group(1).replace("$HOME", home)))
    return out

def tokens(name):
    # ASCII words, plus 4-grams for non-Latin (Thai has no word spaces, so a Thai filename
    # is one long token that would never substring-match a registry description)
    low = name.lower()
    toks = [t for t in re.split(r"[^0-9a-z]+", low)
            if len(t) > 2 and t not in ("new","tmp","test","script","tool")]
    thai = "".join(ch for ch in low if "฀" <= ch <= "๿")
    toks += [thai[i:i+4] for i in range(max(0, len(thai) - 3))]
    return toks

try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input") or {}
    tool = d.get("tool_name","")
    cand = targets_from_bash(ti) if "command" in ti else targets_from_write(ti)

    home = os.path.expanduser("~")
    watched = (os.path.join(home,"bin"), os.path.join(os.environ["AW"],"tools"))
    ackp = os.path.join(os.environ["AW"],".cap-ack")
    seen = set()
    if os.path.exists(ackp):
        seen = {l.strip() for l in open(ackp) if l.strip()}

    fresh = []
    for fp in cand:
        if not fp or not os.path.isabs(fp):        # relative paths: cwd is unspecified here
            continue
        ap = os.path.abspath(fp)
        if not any(ap.startswith(w + os.sep) for w in watched):
            continue
        if not re.search(r"\.(sh|py|mjs|js)$", ap):
            continue
        if os.path.exists(ap) or ap in seen:        # editing an existing tool is fine
            continue
        fresh.append(ap)

    if not fresh:
        print("ALLOW"); sys.exit(0)

    tsv = os.path.join(os.environ["AW"],"capabilities.tsv")
    hits, seen_rows = [], set()
    if os.path.exists(tsv):
        toks = []
        for ap in fresh:
            toks += tokens(os.path.basename(ap))
        for line in open(tsv, encoding="utf-8"):
            if line.startswith("#") or not line.strip():
                continue
            low = line.lower()
            if any(t in low for t in toks):
                c = line.rstrip("\n").split("\t")
                if len(c) >= 4 and c[1] not in seen_rows:
                    seen_rows.add(c[1]); hits.append(f"{c[1]}  ->  {c[3]}")

    with open(ackp,"a",encoding="utf-8") as f:
        for ap in fresh:
            f.write(ap+"\n")
    print("BLOCK:" + "\n".join(hits[:6]))
except Exception:
    print("ALLOW")
' 2>/dev/null)"

case "$res" in
  BLOCK*)
    body="${res#BLOCK:}"
    echo "[CAPABILITY GATE] Creating a NEW tool. Check the registry first so this is not a rebuild." >&2
    if [ -n "$body" ]; then
      echo "Registry entries that look related:" >&2
      echo "$body" >&2
    else
      echo "Nothing similar found in the registry by name." >&2
    fi
    echo "Search properly before proceeding:  cap <what it should do>    (e.g. cap pdf, cap backup)" >&2
    echo "If it genuinely does not exist yet, repeat the same call and it will go through," >&2
    echo "then add a row to ~/.agent-workflow/capabilities.tsv and run: cap --render" >&2
    exit 2 ;;
  *) exit 0 ;;
esac
