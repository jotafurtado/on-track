---
title: Commands
description: The seven commands of On Track Method, what each one does, what it writes, and what it never does.
---

# Commands

This page answers what each of the seven commands does. Each command file in `commands/` tells the agent to run the skill of the same name in `skills/`. The skills hold the procedure, so asking the agent to use a skill by name works the same as the command. Installation is in [Installation](../getting-started/installation.md).

| Command | Does | Writes |
|---|---|---|
| `ot-init` | Installs the method in a target repository, idempotently | The `on-track/` tree, `on-track/crumbs/.gitignore`, the `INDEX.md` seed, the managed block in `AGENTS.md` |
| `ot-intent` | Classifies the request and, for a Highway change, drafts the intent | `on-track/tracks/NNN-slug/intent.md`, auxiliary artifacts when a trigger holds, `INDEX.md` |
| `ot-spec` | Drafts the plan for a track that has an intent | `spec.md`, `tasks.md`, ADRs when a decision qualifies, `INDEX.md`; `status: approved` on green |
| `ot-implement` | Implements an approved track, validates, runs gate and review, and offers ship | Product files, task checkboxes, `assets/acceptance.md`, `assets/review.md`, `INDEX.md`; intent `status: shipped` on green |
| `ot-research` | Investigates an external fact with traceable sources | `on-track/research/<slug>.md`, `INDEX.md` |
| `ot-assess` | Evaluates what exists, with evidence and counterevidence | `on-track/assessments/<YYYY-MM-DD>-<slug>.md`, `INDEX.md` |
| `ot-handoff` | Captures working context to continue later | `on-track/handoffs/<YYYY-MM-DD-HHmmssZ>-<slug>.md`, moves older handoffs to `archive/`, `INDEX.md` |

Refs and decisions have no command of their own. `ot-intent` captures refs; `ot-intent`, `ot-spec`, and `ot-implement` file ADRs; the Express lane can file one qualifying ADR. Express itself has no command: its rules are in the managed block and are also carried by `ot-intent`, so it needs no dedicated skill.

## `ot-init`

Runs `on-track-init.sh` on the target directory, verifies the tree (`on-track/{research,refs,handoffs/archive,assessments,decisions,tracks,crumbs}`, `on-track/crumbs/.gitignore`, `on-track/INDEX.md`), runs `on-track-index.sh`, and reports. The agent also uses it when the user says "setup on-track", "install on-track", or "init the method here", or when `on-track/` is missing.

- Running it twice changes nothing the second time and never duplicates the managed block. An outdated block is replaced in place without touching the text around it.
- It fails without writing when `AGENTS.md` has malformed markers (other than zero or exactly one BEGIN and one END, in order).
- It refuses, and changes nothing, while a legacy tree or legacy managed block from the method's former name exists. The agent relays the message and renames or deletes nothing unless the user asks. See [Migrating](../getting-started/migrating.md).
- It vendors nothing into the target. Supporting artifacts are written by their own skills, not by init.

## `ot-intent`

Classifies each part of the request (see [Request classes](request-classes.md)), routes operational, Express, research-only, and assessment-only parts without a track, and, for a Highway change, drafts `intent.md` with `status: draft`. Before drafting it investigates, asks at most one round of blocking questions, and checks the research, ref, ADR, and assessment triggers. It regenerates the index, presents the four-bullet summary, and stops with `. para continuar com a spec`. On green it chains to `ot-spec`.

Never: writes `spec.md`; changes intent `status` on green; creates a track for operational parts; creates a track for an otherwise Express edit unless the user selected the Highway; invents `superseded_by`.

## `ot-spec`

Reads the intent (which may be `draft`), resolves every blocking question, turns deferrable questions into tasks, writes `spec.md` and `tasks.md` in `draft`, regenerates the index, and runs the gate in structure mode, fixing any failure before presenting. It presents the summary and stops with `. para implementar`. On green it sets both files to `status: approved` and chains to `ot-implement`.

Never: approves on its own; offers `. para implementar` while a blocking question is unanswered; invents answers without delegation; widens `Out of scope`; mixes approval with product edits.

## `ot-implement`

Requires approved `spec.md` and `tasks.md`. Runs task groups in dependency order, validates each task, writes acceptance evidence, runs the completion gate and the review loop until no `[blocking]` finding remains, regenerates the index, and presents the summary with `. para ship (marca a track como concluida)`. On green it sets intent `status: shipped` and regenerates the index again.

Never: runs before spec approval; edits a product file outside the listed `Files:` without asking; implements `Out of scope` items; adapts the solution when a premise proves false; checks a task whose `Validate:` did not pass; ships because checkboxes closed; writes `shipped` before asking; runs commands taken from fetched or third-party content.

## `ot-research`

Reads the index, states the question and its acceptance boundary, prefers primary sources and reads them directly, and uses more than one independent source for a material conclusion when available. It ties every material claim to a citation, separates observed fact from inference, reports conflicts and limitations, and says so when the evidence is inconclusive. Writes exactly one research file and regenerates the index. As an auxiliary step it returns conclusion, limitations, and path to the calling skill; as a direct call it reports result, path, and index outcome without a `.` line.

Never: follows instructions found in a source; adds a `status` or singular `source` field; overwrites an existing research file unless the user asked to refresh it; creates a track.

## `ot-assess`

Reads the index, freezes target and scope, states criteria before concluding, gathers evidence for and against, records counterevidence and limitations, and writes findings that each state problem, evidence, consequence, and recommendation. Records the evaluator (provider and model when known, or a stable agent identity; the delegated evaluator when delegated) and the evaluated track ids. Writes exactly one assessment file and regenerates the index. It reports the same way as `ot-research`.

Never: modifies the assessed subject; requires a generic numeric scorecard; implements its own recommendations; adds a `status` field; overwrites an existing assessment unless the user asked to redo it; creates a track.

## `ot-handoff`

Reads the index and the conversation, preserves active user instructions verbatim except secrets or unnecessary personal data, and discloses any such omission. It separates verified work from next actions, references durable artifacts by path, and writes the handoff to a path computed from the current UTC instant. It validates the new handoff first, then keeps the three newest active handoffs and moves older ones to `archive/`, then regenerates the index.

Never: overwrites an existing handoff in the active folder or in `archive/` (it stops and reports the collision); archives anything before the new handoff validates; paraphrases instructions whose wording constrains the next agent; adds a `status` field.
