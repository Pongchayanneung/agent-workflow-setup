#!/usr/bin/env bash
# Mechanical half of the setup. The personal half (your rules file) is an interview: see SETUP.md.
#
# Usage:  bash install.sh [--tools claude,codex,gemini,agy] [--no-packages] [--install-claude]
#   --tools           which agents to wire (default: every one found on PATH)
#   --no-packages     skip brew/apt (git, python3, jq already installed)
#   --install-claude  also install the Claude Code CLI (other agents: install them yourself)
# Safe to re-run. Anything replaced is copied to ~/.agent-workflow/backups/<timestamp>/ first.
# It never logs in to anything and never writes a secret.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
STAMP="$(date +%Y%m%d-%H%M%S)"; BACKUP="$AW/backups/$STAMP"
PACKAGES=1; GET_CLAUDE=0; TOOLS=""
while [ $# -gt 0 ]; do
  case "$1" in
    --tools) TOOLS="${2:?--tools needs a value}"; shift ;;
    --no-packages) PACKAGES=0 ;;
    --install-claude) GET_CLAUDE=1 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac; shift
done

say() { printf '\n==> %s\n' "$*"; }
# Copy $1 to $2. Identical -> skip. Different -> back the old one up first.
put() {
  local src="$1" dst="$2"; mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ]; then
    cmp -s "$src" "$dst" && return 0
    mkdir -p "$BACKUP"; cp -p "$dst" "$BACKUP/$(basename "$dst")"
    echo "    backed up existing $(basename "$dst") -> $BACKUP"
  fi
  cp -p "$src" "$dst"
}

say "1/6 Toolchain (git, python3, jq)"
if [ "$PACKAGES" = 1 ]; then
  case "$(uname -s)" in
    Darwin)
      command -v brew >/dev/null || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      for p in git python3:python jq; do
        c="${p%%:*}"; f="${p##*:}"; command -v "$c" >/dev/null || brew install "$f"
      done ;;
    Linux) sudo apt-get update -y && sudo apt-get install -y git curl jq python3 ;;
    *) echo "Unsupported OS $(uname -s). Install git python3 jq by hand and re-run with --no-packages."; exit 1 ;;
  esac
else echo "    skipped (--no-packages)"; fi
for c in git python3 jq; do command -v "$c" >/dev/null || { echo "missing required tool: $c" >&2; exit 1; }; done

say "2/6 Agent CLIs"
if [ "$GET_CLAUDE" = 1 ] && ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash; export PATH="$HOME/.local/bin:$PATH"
fi
if [ -z "$TOOLS" ]; then
  for t in claude codex gemini agy; do command -v "$t" >/dev/null && TOOLS="${TOOLS:+$TOOLS,}$t"; done
fi
[ -n "$TOOLS" ] || { echo "    no claude/codex/gemini/agy on PATH. Install one, or pass --tools. Core files still install."; }
echo "    wiring: ${TOOLS:-none}"

say "3/6 Core files -> $AW  (hooks, cap registry, templates)"
for f in "$HERE"/core/hooks/*; do put "$f" "$AW/hooks/$(basename "$f")"; done
chmod +x "$AW"/hooks/*.sh
put "$HERE/adapters/claude/compact_nudge.py" "$AW/adapters/claude/compact_nudge.py"
put "$HERE/core/bin/cap" "$HOME/bin/cap"; chmod +x "$HOME/bin/cap"
put "$HERE/core/templates/AGENTS.md.template" "$AW/AGENTS.md.template"
[ -e "$AW/capabilities.tsv" ]    || put "$HERE/core/templates/capabilities.tsv" "$AW/capabilities.tsv"
[ -e "$AW/pinned_projects.md" ]  || put "$HERE/core/templates/pinned_projects.md" "$AW/pinned_projects.md"
[ -d "$AW/memory" ]              || { mkdir -p "$AW/memory"; cp "$HERE"/core/templates/memory/* "$AW/memory/"; }
case ":$PATH:" in *":$HOME/bin:"*) ;; *) echo "    NOTE: add ~/bin to PATH so 'cap' works:  echo 'export PATH=\"\$HOME/bin:\$PATH\"' >> ~/.zshrc" ;; esac

say "4/6 Smoke-test every hook once (a hook is not wired until it has run)"
sample='{"session_id":"install-smoke","hook_event_name":"BeforeAgent","prompt":"hello","tool_name":"Read","tool_input":{}}'
for f in "$AW"/hooks/*.sh; do
  case "$(basename "$f")" in lib-repos.sh|smoketest.sh|gemini-wrap.sh|agy-wrap.sh) continue ;; esac
  bash "$AW/hooks/smoketest.sh" "$f" "$sample" >/dev/null 2>&1 && echo "    ok  $(basename "$f")" || { echo "    FAILED  $(basename "$f")" >&2; exit 1; }
done
printf '%s' "$sample" | bash "$AW/hooks/gemini-wrap.sh" show_projects.sh | python3 -c 'import sys,json; json.load(sys.stdin)' && echo "    ok  gemini-wrap.sh (emits valid JSON)"
printf '{"conversationId":"s","toolCall":{"name":"write_to_file","args":{"TargetFile":"/tmp/x.txt","CodeContent":"hi"}}}' | bash "$AW/hooks/agy-wrap.sh" enforce_smoketest.sh PreToolUse | python3 -c 'import sys; sys.stdin.read()' && echo "    ok  agy-wrap.sh"
printf '{"transcript_path":"/nonexistent"}' | python3 "$AW/adapters/claude/compact_nudge.py" >/dev/null 2>&1 && echo "    ok  compact_nudge.py"

merge() {  # merge <target-config.json> <template.json>
python3 - "$1" "$2" <<'PY'
import json, os, sys
path, tpl = sys.argv[1:3]
try:
    cur = json.load(open(path)) if os.path.exists(path) else {}
except ValueError:
    sys.exit(f"    {path} is not plain JSON (comments?). Left untouched; add the hooks by hand from {tpl}")
new = json.load(open(tpl))
for k, v in new.get("env", {}).items():
    cur.setdefault("env", {}).setdefault(k, v)
if "permissions" in new:
    cur.setdefault("permissions", {}).setdefault("defaultMode", new["permissions"]["defaultMode"])
if "context" in new:
    names = cur.setdefault("context", {}).get("fileName", [])
    names = [names] if isinstance(names, str) else names
    cur["context"]["fileName"] = names + [n for n in new["context"]["fileName"] if n not in names]
have = {(ev, g.get("matcher", ""), h["command"])
        for ev, groups in cur.get("hooks", {}).items() for g in groups for h in g["hooks"]}
added = 0
for ev, groups in new["hooks"].items():
    for g in groups:
        todo = [h for h in g["hooks"] if (ev, g.get("matcher", ""), h["command"]) not in have]
        if todo:
            cur.setdefault("hooks", {}).setdefault(ev, []).append({**g, "hooks": todo}); added += len(todo)
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(cur, open(path, "w"), indent=2); open(path, "a").write("\n")
print(f"    wired {added} new hook command(s) into {path}")
PY
}
backup_cfg() { [ -f "$1" ] && { mkdir -p "$BACKUP"; cp -p "$1" "$BACKUP/$(basename "$(dirname "$1")")-$(basename "$1")"; } || true; }

say "5/6 Merge hook wiring into each tool's own config (existing settings kept)"
for t in ${TOOLS//,/ }; do
  case "$t" in
    claude) cfg="$HOME/.claude/settings.json"; tpl="$HERE/adapters/claude/settings.json" ;;
    codex)  cfg="$HOME/.codex/hooks.json";     tpl="$HERE/adapters/codex/hooks.json"; echo "    codex: hooks are experimental. If they do not fire, enable the codex_hooks feature (see docs/TOOLS.md)." ;;
    gemini) cfg="$HOME/.gemini/settings.json"; tpl="$HERE/adapters/gemini/settings.json" ;;
    agy)    backup_cfg "$HOME/.agents/hooks.json"
            python3 - "$HOME/.agents/hooks.json" "$HERE/adapters/agy/hooks.json" "$AW" <<'PY'
import json, os, sys
path, tpl, aw = sys.argv[1:4]
try:
    cur = json.load(open(path)) if os.path.exists(path) else {}
except ValueError:
    sys.exit(f"    {path} is not plain JSON. Left untouched; copy the groups from {tpl} by hand")
new = json.loads(open(tpl).read().replace("@AW@", aw))
added = [k for k in new if k not in cur]
cur.update({k: new[k] for k in added})
os.makedirs(os.path.dirname(path), exist_ok=True)
json.dump(cur, open(path, "w"), indent=2); open(path, "a").write("\n")
print(f"    wired {len(added)} new hook group(s) into {path} (agy supports only Pre/PostToolUse hooks)")
PY
            continue ;;
    *) echo "    unknown tool '$t', skipped"; continue ;;
  esac
  backup_cfg "$cfg"; merge "$cfg" "$tpl"
done

say "6/6 Link the shared rules file into each tool's global slot"
if [ -f "$AW/AGENTS.md" ]; then
  for t in ${TOOLS//,/ }; do
    case "$t" in claude) g="$HOME/.claude/CLAUDE.md" ;; codex) g="$HOME/.codex/AGENTS.md" ;; gemini) g="$HOME/.gemini/GEMINI.md" ;; agy) g="$HOME/.agents/AGENTS.md" ;; *) continue ;; esac
    if [ -L "$g" ] && [ "$(readlink "$g")" = "$AW/AGENTS.md" ]; then echo "    already linked  $g"
    elif [ -e "$g" ]; then echo "    EXISTS, not touched: $g  (merge it into $AW/AGENTS.md, then delete it and re-run)"
    else mkdir -p "$(dirname "$g")"; ln -s "$AW/AGENTS.md" "$g"; echo "    linked  $g -> $AW/AGENTS.md"; fi
  done
else
  echo "    $AW/AGENTS.md does not exist yet. Run the interview in SETUP.md, then re-run this script."
fi

cat <<'MSG'

Done with the mechanical part. Still to do BY HAND (these need you, a browser or a secret):
  1. Log in to your agent: run `claude`, `codex` or `gemini` once. See docs/ACCOUNTS.md.
  2. gh auth login (only if you use GitHub).
Then open your agent in this folder and say: "Read SETUP.md and run the setup."
MSG
