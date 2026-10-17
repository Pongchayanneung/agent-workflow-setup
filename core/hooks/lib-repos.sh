# Sourced by wip_autosave.sh and warm_resume.sh so both cover exactly the same repos.
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# Roots to scan (colon-separated). Override: export CLAUDE_WIP_ROOTS="$HOME/code:$HOME/work"
roots="${CLAUDE_WIP_ROOTS:-$HOME/repos:$HOME/projects:$HOME/GitHub:$HOME/code}"
dirs=()
IFS=':' read -r -a _r <<< "$roots"
for root in "${_r[@]}"; do
  [ -d "$root" ] || continue
  while IFS= read -r g; do
    dirs+=("${g%/.git}")
  done < <(find "$root" -maxdepth 3 -name .git -type d -prune 2>/dev/null)
done
