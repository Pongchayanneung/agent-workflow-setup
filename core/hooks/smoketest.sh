#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# Smoke-test a hook script by running it once with a sample payload, then record
# its CONTENT HASH (sha256) + name in ~/.agent-workflow/.smoketested. The gate allows
# wiring exactly this version; editing the script later invalidates the record.
# Hardening: refuses to run anything outside ~/.agent-workflow/hooks/.
# Usage: smoketest.sh <path-to-hook.sh> [sample-json]   (default sample: '{}')
s="$1"; sample="${2:-{}}"
hooks_dir="$AW/hooks"
[ -n "$s" ] || { echo "usage: smoketest.sh <hooks/script.sh> [sample-json]"; exit 1; }
[ -f "$s" ] || { echo "no such script: $s"; exit 1; }

resolved="$(cd "$(dirname "$s")" 2>/dev/null && pwd)/$(basename "$s")"
case "$resolved" in
  "$hooks_dir"/*) ;;
  *) echo "refusing: $s is not under $hooks_dir"; exit 1 ;;
esac

echo "--- running $s with sample: $sample ---"
printf '%s' "$sample" | bash "$s"; rc=$?
echo "--- exit=$rc ---"

name="$(basename "$s")"
sha="$(shasum -a 256 "$s" | awk '{print $1}')"
reg="$AW/.smoketested"; touch "$reg"
# replace any prior record for this name, then append the current hash
tmp="$(mktemp)"; grep -vE "[[:space:]]${name}\$" "$reg" > "$tmp" 2>/dev/null; mv "$tmp" "$reg"
printf '%s  %s\n' "$sha" "$name" >> "$reg"
echo "recorded: $sha  $name"
