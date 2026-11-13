---
title: Installation
description: Install the seven On Track Method skills with npx skills or from a checkout, and keep them up to date.
---

# Installation

This page answers how to install On Track Method in a project, what the installation puts on your machine, and how to update it.

## Requirements

- Node.js 22.20 or later and `npx`, for the `npx skills` installation.
- Git.
- Bash. Every bundled script is local Bash with no network calls.
- A coding agent that supports skills. The package is evaluated with Claude Code, Codex, and Kiro.

## Install with npx skills

From the root of the project where you want to use the method, run:

```bash
npx skills add jotafurtado/on-track --skill '*'
```

The [skills CLI](https://github.com/vercel-labs/skills#install-a-skill) lets you choose the agents and installs into the project by default.

| Option | Effect |
|---|---|
| `--global` | Installs for your user instead of the project, so every project can use the skills. |
| `--agent claude-code`, `--agent codex`, `--agent kiro-cli` | Selects one of the evaluated agents explicitly. |

Install the whole set with `--skill '*'`. Each script and template has one owner skill, and the other skills reach it through sibling paths such as `../ot-init/scripts/on-track-index.sh`. A partial installation can leave a skill pointing at a resource that is not there.

This installation puts the skills in place only, not the command wrappers. Call a skill by name the way your harness does it: `/ot-intent` in Claude Code, `$ot-intent` or the `/skills` picker in Codex, or in any harness a plain request such as `Use the ot-intent skill to <goal>`.

## Install from a checkout

To develop the package, or to keep links to a local checkout, clone the repository and run from its root:

```bash
./install.sh
```

The script links every `skills/ot-*` directory and every `commands/ot-*.md` wrapper into your harness directories. It is idempotent: running it again recreates the links.

| Target | Default | Flag |
|---|---|---|
| Harness skills | `~/.agents/skills` | `--agents-dir DIR` |
| Claude Code skill mirror | `~/.claude/skills` | `--claude-dir DIR` |
| Command wrappers | `~/.claude/commands` | `--commands-dir DIR` |

- The Claude Code mirror is updated only when the parent of the mirror directory exists (by default, when `~/.claude/` exists). Each mirror entry is a relative link to the entry in the harness skills directory.
- When you pass `--claude-dir` without `--commands-dir`, the wrappers go to a `commands` directory next to that skills directory.
- Any other argument stops the script with `ERROR: unknown argument`.

To also expose the skills to Kiro while keeping the default installation, run a second time with its directory:

```bash
./install.sh --agents-dir "$HOME/.kiro/skills"
```

That directory receives links to the same checkout, not an independent copy.

## What gets installed

Seven skills, each with the procedure an agent follows and the resources it owns:

| Skill | Owns |
|---|---|
| `ot-init` | `scripts/on-track-init.sh`, `scripts/on-track-index.sh`, `assets/AGENTS-snippet.md` |
| `ot-intent` | `assets/intent.md`, `assets/ref.md` |
| `ot-spec` | `scripts/on-track-gate.sh`, `assets/spec.md`, `assets/tasks.md`, `assets/decisions.md` |
| `ot-implement` | Its procedure only |
| `ot-research` | `assets/research.md` |
| `ot-assess` | `assets/assessment.md` |
| `ot-handoff` | `assets/handoff.md` |

The checkout installation also links seven command wrappers, `commands/ot-init.md` through `commands/ot-handoff.md`. Each one tells the agent to run the skill of the same name. The `ot-*` names are the skill names, not aliases.

The checkout installer writes links to the configured harness directories. Run `ot-init` in a target project to create its `on-track/` tree, managed block, and index (see [Your first track](first-track.md)).

## Update

- With `npx skills`, run the same `npx skills add` command again to install the current version.
- With a checkout, pull the repository; the links already point at it. Run `./install.sh` again when skills or commands were added or renamed.

After an update that changes the managed block, run `ot-init` again in each project to refresh the block in `AGENTS.md`. It is idempotent and never duplicates the block.

If you used an older release with other skill names, remove those entries from your harness after reinstalling. Projects created before the rename need the steps in [Migrating from fast-track-ai](migrating.md).
