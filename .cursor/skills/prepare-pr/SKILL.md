---
name: prepare-pr
description: Prepares a clean PR branch from the local `working` branch in this repository while excluding the repo-specific local environment commits that should stay only on `working`. Use when the user wants to open a PR upstream without including local devenv, Cursor, or similar environment commits.
---

# Prepare PR

This repository uses a local workflow where `working` intentionally contains local environment commits that stay in source control locally but must not be included in upstream PRs.

## Repo defaults

- Local branch: `working`
- Upstream base: `ups/main`
- Local-only commits are identified by commit subject, not fixed SHAs, because rebasing `working` rewrites local commit IDs.
- Treat any commit whose subject starts with `local:` as local-only.
- Also treat the legacy commit with subject `claude init` as local-only.

## When to use

Use this skill when the user wants a clean PR branch from `working` that contains feature/fix commits but excludes local-only commits.

## Workflow

1. Verify the repo state first.
   - Confirm the current branch is `working`, or ask before proceeding.
   - Run `git status --short --branch`.
   - Run `git fetch ups main`.
   - Inspect `git log --oneline --reverse ups/main..working`.

2. Classify commits in `ups/main..working`.
   - Treat any commit whose subject starts with `local:` as local-only.
   - Also treat `claude init` as local-only until it is renamed/replaced.
   - Treat the remaining commits in that range as PR candidates.
   - If the range contains unexpected local commits that look environment-specific, stop and ask whether to exclude them too.

3. Ask for the PR branch name.
   - Suggest a default based on the non-local commits.
   - Do not guess silently.

4. Create the clean PR branch from upstream.
   - Start from `ups/main`, not from `working`.
   - Create the new branch there.
   - Cherry-pick only the non-local commits from `working`, in original order.

5. Verify the result.
   - Run `git log --oneline --decorate --max-count 10`.
   - Run `git diff --stat ups/main...HEAD`.
   - Confirm the local-only env commits are absent from the new branch.

6. Always draft PR metadata.
   - Generate a PR title based on the non-local commits on the clean branch.
   - Generate a PR body with at least:
     - `## Summary`
     - `## Test plan`
   - The title and body should describe only the non-local changes included in the PR branch.
   - Even if the user only asked for branch preparation, still provide the PR title and body unless they explicitly say not to.

## Command pattern

Use this sequence, adapting the branch name and commit list:

```bash
git status --short --branch
git fetch ups main
git log --oneline --reverse ups/main..working
git switch -c <pr-branch> ups/main
git cherry-pick <non-local-commit-1> <non-local-commit-2>
git log --oneline --decorate --max-count 10
git diff --stat ups/main...HEAD
```

Then produce:

```markdown
Title: <concise PR title>

## Summary
- <1-3 bullets covering the included non-local changes>

## Test plan
- [x] <test command run or validation performed>
```

## Guardrails

- Never remove the env commits from `working`.
- Never rewrite `working` unless the user explicitly asks.
- If cherry-picks conflict, stop and explain the conflict before continuing.
- If there are no non-local commits on `working`, say so and do not create an empty PR branch.
- Prefer local-only commits to use the `local:` prefix.
- Never include local-only commits in the generated PR title or body.
