#!/usr/bin/env bash
AW="${AGENT_WORKFLOW_HOME:-$HOME/.agent-workflow}"; export AW
# SessionEnd hook -- non-destructive WIP snapshot of dirty repos so the next
# session never cold-starts. Captures tracked + untracked changes into a
# `refs/wip/autosave-<ts>` commit WITHOUT touching the working tree, index,
# or current branch (uses a throwaway GIT_INDEX_FILE). Snapshot tree is complete.
#
# Exact recovery: restore into a NEW isolated clone (git clone, fetch the ref, reset --hard).
# A checkout overlay on the live tree keeps deleted/renamed files and is only partial recovery.
# List snapshots:      git -C <repo> for-each-ref refs/wip
log="$AW/wip-autosave.log"
ts="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$(dirname "$log")" || exit 0

# Repos to guard: discovered under CLAUDE_WIP_ROOTS (see lib-repos.sh). Discovery, not a
# hardcoded list, because a list silently goes stale and the repo you forgot is the one you lose.
. "$(dirname "$0")/lib-repos.sh"   # defines $dirs

for d in "${dirs[@]}"; do
  [ -d "$d/.git" ] || continue
  # Need a HEAD to parent the snapshot onto.
  git -C "$d" rev-parse --verify HEAD >/dev/null 2>&1 || continue

  # Skip clean repos: no staged, no unstaged, no untracked changes.
  if git -C "$d" diff --quiet 2>/dev/null \
     && git -C "$d" diff --cached --quiet 2>/dev/null \
     && [ -z "$(git -C "$d" ls-files --others --exclude-standard)" ]; then
    continue
  fi

  # Build the snapshot in a throwaway index so the real index is untouched.
  # NOTE: GIT_INDEX_FILE must point at a path that does NOT yet exist, or git
  # treats an empty file as a corrupt index and add -A fails silently.
  tmpd="$(mktemp -d "${TMPDIR:-/tmp}/wipidx.XXXXXX")"
  idx="$tmpd/index"
  if GIT_INDEX_FILE="$idx" git -C "$d" add -A 2>/dev/null; then
    tree="$(GIT_INDEX_FILE="$idx" git -C "$d" write-tree 2>/dev/null)"
    # Comparing trees preserves recovery data while skipping identical snapshots.
    latest="$(git -C "$d" for-each-ref --sort=-refname --count=1 --format='%(refname)' 'refs/wip/autosave-*')"
    # The pointer disambiguates snapshots created within the same second.
    git -C "$d" rev-parse --verify refs/wip/latest-autosave >/dev/null 2>&1 && latest="refs/wip/latest-autosave"
    previous_tree=""
    [ -n "$latest" ] && previous_tree="$(git -C "$d" rev-parse "$latest^{tree}" 2>/dev/null)"
    if [ -n "$tree" ] && [ "$tree" != "$previous_tree" ]; then
      commit="$(git -C "$d" commit-tree "$tree" -p HEAD \
                 -m "wip-autosave $ts (SessionEnd)" 2>/dev/null)"
      if [ -n "$commit" ]; then
        # Commit suffix prevents two different snapshots in one second overwriting.
        ref="refs/wip/autosave-$ts-${commit:0:12}"
        if git -C "$d" update-ref "$ref" "$commit"; then
          git -C "$d" update-ref refs/wip/latest-autosave "$commit"
          echo "[$ts] $d -> $commit  snapshot: $ref" >> "$log"
        fi
      fi
    fi
  fi
  rm -rf "$tmpd"
done

exit 0
