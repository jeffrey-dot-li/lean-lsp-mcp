---
name: sync-main
description: Syncs the local `working` branch in this repository with `ups/main` while preserving the repo-specific local environment commits that should remain on `working`. Use when the user wants to pull upstream main into `working` without losing local devenv or Cursor setup commits.
---

# Sync Main

This repository uses a local `working` branch that intentionally carries local environment commits which should stay on `working` even after syncing with upstream.

## Repo defaults

- Local branch: `working`
- Upstream base: `ups/main`
- Local-only commits are identified by commit subject, not fixed SHAs, because rebasing `working` rewrites local commit IDs.
- Treat any commit whose subject starts with `local:` as local-only.
- Also treat the legacy commit with subject `claude init` as local-only.

## When to use

Use this skill when the user wants to update `working` from `ups/main` but keep local-only commits on top of the refreshed branch.

## Workflow

1. Verify the repo state first.
   - Confirm the current branch is `working`, or ask before proceeding.
   - Run `git status --short --branch`.
   - If there are uncommitted changes, ask whether to stop or stash them first.

2. Refresh upstream refs.
   - Run `git fetch ups main`.
   - Inspect `git log --oneline --reverse ups/main..working`.

3. Check what will be replayed.
   - Preserve any commit whose subject starts with `local:`.
   - Also preserve `claude init` until it is renamed/replaced.
   - If there are additional commits on `working`, call them out and ask whether they should also remain on `working` after the sync.

4. Rebase `working` onto `ups/main`.
   - Prefer a normal rebase so the local commits are replayed onto the updated upstream base.
   - If only the default env commits are present, that is the intended happy path.

5. Verify the result.
   - Run `git log --oneline --decorate --max-count 10`.
   - Confirm `working` is now based on `ups/main` and still contains the local env commits.

## Command pattern

Use this sequence:

```bash
git status --short --branch
git fetch ups main
git log --oneline --reverse ups/main..working
git switch working
git rebase ups/main
git log --oneline --decorate --max-count 10
```

## Guardrails

- Never drop the local env commits from `working`.
- Never force-push unless the user explicitly asks.
- If the rebase conflicts, stop and explain which commit is conflicting.
- If `working` contains extra non-env commits, ask whether the user wants them preserved there or moved to a clean PR branch with the `prepare-pr` skill.
- Prefer local-only commits to use the `local:` prefix.
