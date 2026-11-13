---
title: Committing
description: The method never commits; how crumbs and tracks feed the commit you or your tooling prepares.
---

# Committing

This page answers who commits, how the crumbs left by Express changes feed the commit, and what the person or tool preparing the commit does with them.

## The method never commits

No stage of On Track Method commits, pushes, or deploys. Express ends with a report; the Highway ends with ship, which sets the intent `status: shipped` and regenerates `on-track/INDEX.md`. The commit belongs to you, or to whatever agent or tool you ask to prepare it.

A Highway track already explains itself at commit time: its intent, spec, and tasks hold the why. Express changes have no track, so each one leaves a crumb instead.

## What a crumb gives the commit

Each Express change writes one crumb under `on-track/crumbs/`, after its check, pass or fail. The shape is in [Express changes](express-changes.md#the-crumb).

| Crumb part | Used for |
|---|---|
| `files` and `## Changes` | Grouping the diff: which hunks belong to this change. |
| `## Request` and `## Cause` | Writing the commit message. |

The crumb also records under `## Verification` the check the agent ran and its result.

A crumb records an Express change for commit preparation. Check its files against `HEAD` before using it; stale crumbs must be deleted.

## Preparing commits from crumbs

Whoever prepares the commits, a person or an agent:

1. Reads the crumbs oldest first. The file name starts with the UTC timestamp, so name order is time order.
2. Groups the diff by each crumb's `files` and `Changes`.
3. Writes each commit message from the crumb's `Request` and `Cause`.
4. Deletes every crumb it consumed.
5. Deletes every crumb whose files no longer differ from `HEAD`, since that change is already committed or was undone.

```text
on-track/crumbs/
  2026-11-10-143205Z-footer-typo.md      files: [src/partials/footer.html]
  2026-11-10-151840Z-signup-button.md    files: [src/styles/button.css, tests/button.snap]
```

Read these two crumbs in timestamp order and use their `files` and `Changes` to group the diff. Use `Request` and `Cause` to prepare the commit messages.

## Crumbs are local

Crumbs never enter git and never enter the index. `ot-init` creates `on-track/crumbs/.gitignore` with the single line `*`, which ignores the folder and the `.gitignore` itself. A fresh clone therefore has no `crumbs/` folder; the agent creates it, and its `.gitignore`, when an Express change needs it.

Crumbs live only in the working copy where the change was made. Undoing an Express change deletes its crumb (see [Express changes](express-changes.md#undoing-an-express-change)).
