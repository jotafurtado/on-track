---
title: Express changes
description: When a request takes the Express lane, how to choose the lane yourself, what the agent does, and how to undo an Express change.
---

# Express changes

This page answers when an edit takes the Express lane, how to force either lane, what the agent does on it, what the crumb is, how to undo an Express change, and what happens when the change turns out bigger than it looked.

The Express lane is for small, bounded, reversible edits. It has no track, no intent, no spec, and no stop for a signal: the agent implements, checks, leaves a note, and reports.

## When a request takes the Express lane

All five criteria must hold:

1. The request states what to build, with no open question that would change it.
2. At most three files change.
3. Nothing in this list changes: a public contract (API, CLI flags, schema, a file format someone consumes), persisted data or a migration, a security control (authentication, authorization, secrets, permissions), or a dependency (added, upgraded, or removed).
4. Reverting the diff alone undoes the change, with no data backfill and no external side effect.
5. One existing command or one observable check verifies it.

If any criterion is uncertain, the edit takes the Highway. The Highway is the default.

Examples in a small marketing site:

| Request | Lane | Why |
|---|---|---|
| "Fix the typo in the footer copyright line." | Express | One file, nothing open, the page shows the result. |
| "Change the signup button color to the brand green and update its snapshot." | Express | Two files, verified by the existing snapshot test. |
| "Add a pricing table that reads plans from the API." | Highway | Open design questions remain (layout, plan order, error state), so criterion 1 fails. |
| "Add a `--draft` flag to the build script." | Highway | Changes CLI flags, a public contract. |
| "Upgrade the CSS framework." | Highway | Changes a dependency. |

A compound request is split first. "Run the tests, then fix the footer typo" runs the tests as operational work, with no artifact, and fixes the typo on the Express lane.

## Choosing the lane yourself

Your explicit choice wins in both directions:

- **Highway**: name `ot-intent`, or ask for a track or an intent. Even a one-line fix then gets the full cycle.
- **Express**: ask to do it directly or without a track.

```text
Fix the footer typo directly, no track.
```

## What the agent does

1. Says in one sentence that the change takes the Express lane.
2. Implements it.
3. Runs the check.
4. Writes a crumb with the check result, whether it passed or failed.
5. Reports what changed and the result.

That report ends the work. There is no summary with a next-step line and no wait for a signal.

Apart from the crumb, the agent creates no track and no file under `on-track/`, and does not regenerate the index. The single exception is a decision that meets the ADR threshold (see [Thresholds](../reference/thresholds.md)): the agent files only that ADR and regenerates the index.

## The crumb

A crumb is the local note an Express change leaves for whoever prepares the commit. It lives at `on-track/crumbs/<YYYY-MM-DD-HHMMSSZ>-<slug>.md`, with the timestamp in UTC.

```markdown
---
created: 2026-11-10T14:32:05Z
files:
  - src/partials/footer.html
---

## Request

Fix the typo in the footer copyright line.

## Cause

The year range was typed as "2024-2O26" with a capital O.

## Changes

- `src/partials/footer.html`: corrected the year range.

## Verification

Opened the home page; the footer reads "2024-2026".
```

| Part | Content |
|---|---|
| `created` | The UTC instant, ISO 8601. |
| `files` | Every path the change touched, a filed ADR included. |
| `## Request` | What you asked, in one or two sentences. |
| `## Cause` | Fixes only: the cause found. |
| `## Changes` | One line per file. |
| `## Verification` | The command or observation, and its result. |

A crumb has no `id`, no `status`, and no track number. It stays out of git and out of the index. When `on-track/crumbs/.gitignore` is missing, for example in a fresh clone, the agent creates it with the single line `*`. How crumbs are consumed is in [Committing](committing.md).

## Undoing an Express change

Ask the agent to undo it. The agent reverses its own edits hunk by hunk, so any uncommitted work of yours in the same files survives, and deletes the change's crumb. It does not restore whole files from git.

## When a criterion stops holding

If, while working, the agent finds that a criterion no longer holds (a fourth file is needed, a dependency must change, an open question appears), it stops before the edit that would break the criterion, names the failed criterion, and starts the Highway with `ot-intent`. From there the request follows [Your first track](../getting-started/first-track.md).
