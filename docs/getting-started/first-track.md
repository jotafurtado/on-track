---
title: Your first track
description: Initialize On Track Method in a repository and take one Highway request from intent to ship.
---

# Your first track

This page answers what `ot-init` creates in your repository and what happens, stage by stage, when you take one request down the Highway: what the agent writes, what it shows you, and what you type at each signal.

The example project is a small marketing site. The request is a new version of its landing page, which becomes track `001-lp-v2`.

## Initialize the repository

Open your agent in the project root and run the init skill:

```text
/ot-init
```

You can also ask in plain words: `setup on-track`, `install on-track`, or `init the method here`. The skill also applies when the `on-track/` tree is missing.

`ot-init` runs `on-track-init.sh`, then `on-track-index.sh`, and reports the result. It creates:

```text
AGENTS.md              managed block added or refreshed
on-track/
  INDEX.md             generated index, seeded empty
  research/
  refs/
  assessments/
  decisions/
  handoffs/
    archive/
  crumbs/
    .gitignore         a single line: *
  tracks/
```

- **The managed block** is the text between `<!-- BEGIN MANAGED BLOCK: on-track. Installed by ot-init, idempotent block. -->` and `<!-- END MANAGED BLOCK: on-track -->` in `AGENTS.md`. It tells any agent working in the repository how to classify requests, when to ask, how signals work, and where artifacts live. If `AGENTS.md` does not exist, init creates it with the block. If the block exists, init replaces it in place and leaves the rest of the file untouched.
- **`on-track/INDEX.md`** is generated from the frontmatter of the files under `on-track/`. Agents read it before looking for a track or a supporting artifact. Do not edit it by hand: the next generation overwrites it.
- **`on-track/crumbs/`** holds the local notes that Express changes leave for the commit. Its `.gitignore` keeps the folder out of git. Init never overwrites an existing `.gitignore` there.

Init is idempotent: run it twice and nothing is duplicated. It stops with an error and changes nothing when the `on-track` markers in `AGENTS.md` are malformed (anything other than no markers at all, or exactly one BEGIN followed by one END), or when it finds the legacy layout described in [Migrating from the previous name](migrating.md).

Init writes nothing else. Supporting artifacts are written later by the skills that own them.

## Make a request

Start a change with a concrete request. Naming the intent skill selects the Highway even for a small change:

```text
/ot-intent Rebuild the landing page with the new hero, pricing table, and signup form.
Do not change the blog layout.
```

Without the skill name, the agent classifies the request itself. A request that does not meet all five Express criteria takes the Highway. See [Request classes](../reference/request-classes.md).

## Stage 1: intent

The agent investigates the repository first. If a blocking question remains, one whose answer changes scope, security, persistence, external integration, architecture, or acceptance, it asks all of them in one round of at most four, each with options and its recommendation first. See [Questions and delegation](../guides/questions-and-delegation.md).

It then writes `on-track/tracks/001-lp-v2/intent.md` with `status: draft`, regenerates the index, and presents a summary:

```text
- Problem: the current landing page has no pricing section and its signup form posts to a removed endpoint.
- Outcome: a new landing page with hero, pricing table, and a working signup form.
- Scope: src/pages/index.html, src/styles/landing.css, src/scripts/signup.js.
- Constraints: the blog layout does not change.

Track: on-track/tracks/001-lp-v2/
. para continuar com a spec
```

The four bullets are always problem, proposed outcome, scope, and constraints. When they apply, two more lines appear before the track location: constraints the agent proposed, so you can veto them, and a warning when the problem or the outcome rests on an unverified assumption. Any research, ref, ADR, or assessment the agent created on the way is listed too.

The next-step line is Portuguese in the package and reads as "`.` to continue with the spec".

Now the agent stops and waits for your signal. Open `intent.md` if you want to read it in full, then reply:

| You type | What happens |
|---|---|
| `.` | The agent runs the spec stage for the same track. |
| `Also keep the old signup form working until launch.` | Yellow: the agent revises the intent, regenerates the index, and shows the summary again. |
| `x` | The agent stops. The intent stays in `draft` and the track resumes when you ask for this stage again. |

Green does not approve the intent. It stays `draft` until ship.

## Stage 2: spec

The spec stage reads the intent and resolves every remaining blocking question before presenting the summary, in as many rounds of at most four questions as needed. It writes two files, both with `status: draft`:

- `spec.md`: the outcome, numbered phases, constraints, and out of scope. Each phase has `Done:` (the observable delivered state), `Files:` (the explicit list of files it touches), and `Accept:` (the command or observation that proves it).
- `tasks.md`: tasks grouped under `## Group <name>` headers, with `(depends: <group>)` on a group that must wait for another. Each task carries a `(Phase N)` tag, `Files:`, and `Validate:`.

It regenerates the index, runs the gate in structure mode as an internal check, and presents:

```text
- Outcome: the new landing page is implemented with a working signup form.
- Phases: 1 markup and styles, 2 signup form.
- Tasks: 3.
- Groups: A (markup, styles), B depends on A (signup script).

Track: on-track/tracks/001-lp-v2/
. para implementar
```

The next-step line reads as "`.` to implement". Decisions you delegated with "you decide" are listed before the track location so you can veto them.

| You type | What happens |
|---|---|
| `.` | The agent sets `status: approved` in both `spec.md` and `tasks.md`, as an approval-only step, then starts implementation. |
| `Merge phases 1 and 2.` | Yellow: the agent revises spec or tasks, regenerates the index, reruns the structure gate, and shows the summary again. |
| `x` | The agent stops. Both files stay in `draft`. |

Your green covers exactly the spec and tasks you were shown. A later material change to either file returns both to `draft` and needs a new summary and a new green. See [Highway signals](../guides/highway-signals.md).

## Stage 3: implement

With `spec.md` and `tasks.md` approved, the agent:

1. Runs the task groups in dependency order. Tasks in one group may run in parallel; a dependent group starts only after every task it depends on has passed `Validate` and is checked.
2. Restricts product edits to the files listed in the spec and each task, and never implements `Out of scope`. Before touching another product file, it stops and asks. Method-administration files change only through the transitions defined by `ot-implement`.
3. Runs each task's `Validate` and the checks the project already has, and checks the task `- [x]` only when they pass.
4. Writes `assets/acceptance.md`, a table with one row for the outcome and one per phase `Accept:` line, each executed and marked `met` or `pending`.
5. Runs the completion gate and a review of the diff. It fixes every `[blocking]` finding and every `[important]` finding whose fix stays inside the spec's files, and records every finding in `assets/review.md`. After each required review fix, it reruns affected tasks' `Validate` commands and affected phases' acceptance checks, updates the affected acceptance rows, and reruns the completion gate. It repeats the review until no `[blocking]` finding remains.

On resume, checked tasks are already validated: the agent continues from the first open task in dependency order, and reruns a checked task's `Validate` only if a later change touched its `Files`. If a prerequisite task fails `Validate`, the agent keeps it open, stops before every dependent group, and reports the failure.

Before a task depends on an `Unverified assumptions` entry, the agent verifies it. If a user-stated fact, a session-verified fact, or an assumption proves false, it records the divergence under the track's `assets/`, stops, and reports it before changing the approach.

When the work is done, the agent regenerates the index and presents:

```text
- Tasks: 3/3 completed.
- Acceptance: 3/3 met (assets/acceptance.md).
- Review: 2 fixed, 1 open; no open [important] (assets/review.md).
- Gate: PASS.

. para ship (marca a track como concluida)
```

The next-step line reads as "`.` to ship (marks the track as done)". It appears only when every acceptance row is `met` and no `[blocking]` finding remains.

## Stage 4: ship

| You type | What happens |
|---|---|
| `.` | The agent sets intent `status: shipped` and regenerates the index. The track is done. |
| `Fix the open nit in signup.js too.` | Yellow: the agent makes the fix, reruns the affected checks, and shows the summary again. |
| `x` | The agent stops. The code stays as it is and ship remains available when you ask for it. |

Checked boxes and a passing gate never ship a track by themselves. Ship does not commit, push, or deploy. The commit is yours; see [Committing](../guides/committing.md).

## What the track looks like at the end

```text
on-track/tracks/001-lp-v2/
  intent.md        status: shipped
  spec.md          status: approved
  tasks.md         status: approved, every task checked
  assets/
    acceptance.md
    review.md
```

`INDEX.md` shows the track with status `shipped` and phase `-`. The file shapes are in [Artifacts](../reference/artifacts.md); every stage rule is in [Cycle](../reference/cycle.md).
