#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# SessionStart hook -- echo pinned projects. Mac port of show_projects.ps1.
path="$AW/pinned_projects.md"
if [ -f "$path" ]; then
  echo "=== PINNED PROJECTS ==="
  cat "$path"
  echo "=== /END PROJECTS ==="
fi
