#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# SessionStart hook -- warm resume. Surfaces uncommitted work + recent WIP
# snapshots so a new session starts warm, not cold. Mirror of the SessionEnd
# wip_autosave.sh. stdout becomes additionalContext for the model.
# Same repo set as wip_autosave.sh via lib-repos.sh, so resume reports on what the net snapshots.
. "$(dirname "$0")/lib-repos.sh"   # defines $dirs

any=0
body=""
for d in "${dirs[@]}"; do
  [ -d "$d/.git" ] || continue
  n="$(git -C "$d" status --porcelain 2>/dev/null | grep -c . )"
  if [ "${n:-0}" -gt 0 ]; then
    b="$(git -C "$d" branch --show-current 2>/dev/null)"
    body+="  - $(basename "$d") [${b}]: ${n} uncommitted file(s)"$'\n'
    any=1
  fi
done

snaps=""
[ -f "$AW/wip-autosave.log" ] && snaps="$(tail -3 "$AW/wip-autosave.log" | sed 's/  recover:.*$//')"

if [ "$any" = 1 ] || [ -n "$snaps" ]; then
  echo "=== WARM RESUME (work carried between sessions) ==="
  [ "$any" = 1 ] && printf "%s" "$body"
  if [ -n "$snaps" ]; then
    echo "  recent WIP snapshots:"
    printf "%s\n" "$snaps" | sed 's/^/    /'
    echo "  Exact recovery uses a NEW isolated clone, preserving deletions/renames."
    echo "  List snapshots: git -C <repo> for-each-ref refs/wip   (restore into a NEW clone, never over the live tree)"
  fi
fi
exit 0
