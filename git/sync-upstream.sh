#!/usr/bin/env bash
# Safe post-commit synchronization: fetch and fast-forward, never rebase.
set -euo pipefail

if [[ "${1:-}" == --help || "${1:-}" == -h ]]; then
  printf '%s\n' \
    'Usage: MAIN_BRANCH=main bash git/sync-upstream.sh' \
    'Fetch all remotes and fast-forward to origin/$MAIN_BRANCH (default: main).' \
    'Skip unfinished work, detached HEAD, active Git operations and diverged history.' \
    'Never rewrite commits, stash changes, resolve conflicts or abort manual operations.'
  exit 0
fi
if (( $# )); then
  printf '%s\n' 'Unexpected arguments. Run: bash git/sync-upstream.sh --help' >&2
  exit 2
fi

git rev-parse --show-toplevel >/dev/null
can_sync() {
  for state in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
    if [[ -e "$(git rev-parse --git-path "$state")" ]]; then
      printf '%s\n' 'Skipping automatic sync: a Git operation is in progress.'
      return 1
    fi
  done
  if ! git symbolic-ref -q HEAD >/dev/null; then
    printf '%s\n' 'Skipping automatic sync: HEAD is detached.'
    return 1
  fi
  if [[ -n "$(git status --porcelain --untracked-files=normal)" ]]; then
    printf '%s\n' 'Skipping automatic sync: worktree or index has uncommitted changes.'
    return 1
  fi
  return 0
}
can_sync || exit 0

branch="${MAIN_BRANCH:-main}"
upstream="refs/remotes/origin/$branch"
if ! git check-ref-format "$upstream"; then
  printf '%s\n' 'Invalid MAIN_BRANCH. Set it to an existing origin branch.' >&2
  exit 2
fi
head_before=$(git rev-parse HEAD)
branch_before=$(git symbolic-ref HEAD)
git fetch --all
can_sync || exit 0
if [[ "$(git rev-parse HEAD)" != "$head_before" || "$(git symbolic-ref HEAD)" != "$branch_before" ]]; then
  printf '%s\n' 'Skipping automatic sync: HEAD changed while fetching.'
  exit 0
fi
if ! git rev-parse --verify "$upstream^{commit}" >/dev/null 2>&1; then
  printf 'Missing origin/%s. Set MAIN_BRANCH to an existing origin branch.\n' "$branch" >&2
  exit 1
fi
if git merge-base --is-ancestor "$upstream" HEAD; then
  printf 'Already contains origin/%s; local commits preserved.\n' "$branch"
  exit 0
fi
if git merge-base --is-ancestor HEAD "$upstream"; then
  git merge --ff-only "$upstream"
  exit 0
fi
printf 'Skipping automatic sync: history diverged from origin/%s.\n' "$branch"
printf 'To reconcile manually: git rebase %q\n' "origin/$branch"
