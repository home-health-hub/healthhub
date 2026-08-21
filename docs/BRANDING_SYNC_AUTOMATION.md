---
title: Branding Sync Automation (design)
layout: default
---

# Branding sync automation — automatic lock-file update

**Scope:** this covers the automatic-lock-update route for keeping each daemon
repo's copy of its approved branding assets (banner/icon/nav-icon PNGs) in
sync with the canonical `healthhub-branding` repo, with a human merge gate
on the visual change itself but no manual step for the bookkeeping that
follows.

**Status:** design only, not implemented. Written for handoff to whoever
picks up `healthhub-branding` next (Codex, at time of writing) — check the
current shape of `branding.lock.json` before building against the field
names below, they're illustrative, not confirmed against what's actually
there now.

## Components

- `healthhub-branding` — canonical repo, owns `approved/` assets and
  `branding.lock.json`.
- Each daemon repo — consumes assets into its own `docs/images/`.
- A GitHub App (or fine-grained PAT) installed on the org, scoped to
  `contents: write` + `pull-requests: write` on the daemon repos only —
  least-privilege, auditable, not a personal token.

## Flow

1. **Detect drift.** On push to `healthhub-branding` main, a workflow reads
   `branding.lock.json`, diffs each destination's recorded checksum against
   the current `approved/` file, and collects the stale ones.

2. **Open sync PRs.** For each stale destination: branch
   `branding-sync/<repo>-<asset>`, copy the new file into `docs/images/`
   (filenames stay stable, nothing else changes), commit, push, open a PR.
   Reuse/force-push the same branch name on a re-run instead of opening a
   second PR for the same destination.

3. **Human merge.** Unchanged from the current process — review the visual
   diff (GitHub renders PNG diffs natively) and merge like any other PR.

4. **Report back — this is the automatic part.** Once a `branding-sync/*`
   PR merges in a daemon repo, something has to tell `healthhub-branding`
   "this destination is now current." Two ways to build it:

   **Option A — polling (recommended default).** A scheduled workflow in
   `healthhub-branding` periodically reads each daemon repo's
   `docs/images/*` directly via the GitHub Contents API, computes
   checksums, and updates `branding.lock.json` to match whatever's actually
   merged. No changes needed in any daemon repo, no cross-repo secret to
   distribute to 8+ repos. Downside: a polling-interval delay before the
   lock file reflects reality — harmless, since the lock file is only
   bookkeeping, not something gating anything time-sensitive.

   **Option B — event callback (lower latency).** Each daemon repo's own
   CI, on merging a `branding-sync/*` PR specifically, fires a
   `repository_dispatch` back to `healthhub-branding` with
   `{repo, asset, checksum}`. Requires adding a small callback step to
   every daemon repo's workflow and a token with dispatch rights stored in
   each of them — more moving parts, spread across every repo instead of
   centralized in one.

   Recommendation: start with A. It's centralized (one workflow to
   maintain, not one per daemon repo) and the lock file has no reason to be
   real-time.

5. **Lock-file commit.** Whichever detection method is used, the lock-file
   update itself is a small, fully mechanical, non-visual JSON change —
   safe to auto-merge (or even direct-commit if `healthhub-branding`'s
   branch protection allows a bot exception), since there's nothing
   subjective for a human to review in "checksum X is now the adopted value
   for destination Y."

## Idempotency / safety notes

- Never open a second competing PR for the same destination — check for an
  existing `branding-sync/*` branch first and update it in place.
- The GitHub App's write access should be scoped to exactly the daemon
  repos, not the whole org, and to `contents`/`pull-requests` only — no
  admin, no other repos.
- Nothing here needs a direct push to any daemon repo's `main` — branch
  protection stays intact everywhere.
