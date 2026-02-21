#!/usr/bin/env bash
set -euo pipefail

# Simple deploy script: pushes site root to the `gh-pages` branch using a temporary worktree.
# Update `BRANCH` or `ORIGIN` as needed. Run: ./deploy.sh

BRANCH=gh-pages
ORIGIN=origin

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to deploy" >&2
  exit 1
fi

REPO_URL=$(git config --get remote.$ORIGIN.url || git config --get remote.origin.url)
if [ -z "$REPO_URL" ]; then
  echo "Unable to determine remote repository URL. Configure a remote named '$ORIGIN'." >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
echo "Preparing deploy worktree in $TMPDIR"

# Ensure branch exists locally (create orphan if necessary)
if git show-ref --verify --quiet refs/heads/$BRANCH; then
  git worktree add "$TMPDIR" "$BRANCH"
else
  git worktree add --detach "$TMPDIR"
  pushd "$TMPDIR" >/dev/null
  git init
  git remote add origin "$REPO_URL"
  git checkout -b "$BRANCH"
  popd >/dev/null
fi

# Copy files (exclude .git)
rsync -av --delete --exclude='.git' ./ "$TMPDIR"/

pushd "$TMPDIR" >/dev/null
git add -A
git commit -m "Deploy to GitHub Pages: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" || true
git push "$ORIGIN" "$BRANCH" --force
popd >/dev/null

git worktree remove "$TMPDIR" || rm -rf "$TMPDIR"
echo "Deployed to $BRANCH"
