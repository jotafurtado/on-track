---
title: Migrating from fast-track-ai
description: Move a project from the fast-track-ai layout to the on-track layout by hand, then run ot-init.
---

# Migrating from fast-track-ai

This page answers how to move a project that used the method under its previous name, `fast-track-ai`, to the current On Track Method layout. There is no automatic migration: you make five manual steps, and `ot-init` checks the result.

## What changed

| Before | Now |
|---|---|
| Tree `fast-track-ai/` | Tree `on-track/` |
| Skills and commands `ft-*` | Skills and commands `ot-*` |
| Managed block `fast-track-ai` in `AGENTS.md` | Managed block `on-track` in `AGENTS.md` |

The install command and the repository slug did not change.

## Steps

1. Reinstall the skills. The command is the same:

   ```bash
   npx skills add jotafurtado/on-track --skill '*'
   ```

   Remove the old skill and command entries from your harness. The new names are not aliases of the old ones.

2. In each project, rename the folder `fast-track-ai/` to `on-track/`.

   ```bash
   git mv fast-track-ai on-track
   ```

3. Replace `fast-track-ai/` with `on-track/` in the paths inside the files of that folder.

4. In `AGENTS.md`, delete the old managed block, everything from its `<!-- BEGIN MANAGED BLOCK: fast-track-ai` marker to its END marker.

5. Run `ot-init`. It writes the new managed block, creates any missing folder (including `on-track/crumbs/` with its `.gitignore`), and regenerates `on-track/INDEX.md`. Read its report and resolve any index validation errors; the index is not updated while validation fails.

## Why ot-init refuses

`ot-init` checks for the legacy layout before doing anything else. While either of these exists, it prints a `FAIL:` message with the manual step for each one, exits with an error, and changes nothing:

| Found | Message tells you to |
|---|---|
| A `fast-track-ai` file, folder, or link in the project root | Rename it to `on-track/` and replace `fast-track-ai/` with `on-track/` in the paths inside its files. |
| A line in `AGENTS.md` starting with `<!-- BEGIN MANAGED BLOCK: fast-track-ai` | Delete everything from its BEGIN marker to its END marker. |

When both exist, both messages appear. The agent relays the message and stops; it renames or deletes nothing unless you ask.
