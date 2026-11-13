---
title: Cycle
description: The Highway stages (intent, spec, implement, ship), what each writes, the status values and who changes them, implementation limits, task groups, and resume.
---

# Cycle

This page answers what happens at each stage of the Highway, which files each stage writes, which status values exist and who may change them, and what limits bind implementation. The answers the user gives at each stop are in [Signals](signals.md).

```
intent ──► spec ──► implement ──► ship
```

Each of the first three stages ends with a four-bullet summary and a next-step line, then stops for the user's signal. The next-step lines are written in Portuguese by the package and appear exactly as below.

| Stage | Skill | Writes | Summary bullets | Next-step line |
|---|---|---|---|---|
| Intent | `ot-intent` | `intent.md` with `status: draft` | Problem, proposed outcome, scope, constraints | `. para continuar com a spec` ("`.` to continue with the spec") |
| Spec | `ot-spec` | `spec.md` and `tasks.md` with `status: draft` | Outcome, phases, task count, parallel groups | `. para implementar` ("`.` to implement") |
| Implement | `ot-implement` | Product files, task checkboxes, `assets/acceptance.md`, `assets/review.md` | Completed tasks, acceptance, review outcome, gate result | `. para ship (marca a track como concluida)` ("`.` to ship, marks the track as done") |
| Ship | `ot-implement` | Intent `status: shipped`, regenerated index | None | None |

## Intent

`ot-intent` classifies the request (see [Request classes](request-classes.md)), finds the next free number under `on-track/tracks/`, and drafts `on-track/tracks/NNN-slug/intent.md` from its template. The track id is three digits and a kebab-case slug of what was asked, for example `007-lp-v2`.

Before drafting, the agent investigates and asks only blocking questions, in one round of at most four. Blocking questions beyond the cap go under `Open questions` for the spec stage. See [Questions and delegation](../guides/questions-and-delegation.md). It also checks whether a research, ref, ADR, or assessment is warranted, says so in one sentence, and writes it without asking permission. See [Supporting artifacts](../guides/supporting-artifacts.md) and [Thresholds](thresholds.md).

The intent stage never writes `spec.md`. The skill regenerates the index and reports any validation error instead of presenting the summary as complete.

The intent summary carries two extra lines only when they apply, placed before the track location and the next-step line:

- the constraints the agent proposed, so the user can veto them;
- a warning when the Problem or Proposed outcome rests on an entry under `Unverified assumptions`, naming that entry.

The summary also lists generated artifacts (research, refs, ADRs, assessments), if any, and the track location. It does not report draft status as a failure and does not present an approval gate.

## Spec

`ot-spec` reads `intent.md`. The intent may still be `draft`; intent approval is not required before the spec.

It classifies every unanswered item under `Open questions`:

- **Blocking question**: its answer changes scope, security, data persistence, external integration, architecture, or acceptance. Every blocking question is resolved before the summary, in as many rounds of at most four as needed. The agent withholds the summary and does not offer `. para implementar` while any remains unanswered.
- **Deferrable question**: its answer does not block overall architecture or scope. It becomes a bounded task whose `Validate:` names the expected answer or artifact, in a group that dependent groups list in `(depends: ...)`.

Without delegation, the agent does not invent answers to either kind.

The skill writes `spec.md` and `tasks.md` from its templates. Every constraint in the intent binds the spec, whatever its provenance. `Out of scope` repeats the intent limit without widening it. Each phase has `Done:` (the delivered, observable state), `Files:` (the explicit list of touched files), and `Accept:` (a command with its expected result, or an observable procedure with its expected observation).

Then it regenerates the index and runs the gate in structure mode as an internal smoke test, fixing any failure before presenting the draft. See [Validation](validation.md).

The spec summary lists delegated decisions before the track location and the next-step line, only when there are any.

## Implement

`ot-implement` requires `intent.md` and `status: approved` in both `spec.md` and `tasks.md`. Without them there is no Highway implementation. The intent may still be `draft`.

The stage runs in this order:

1. Create all tasks in the harness task tracker, if one exists, with phase tags.
2. Run the task groups in dependency order (see [Task groups](#task-groups-and-dependencies)).
3. Run each task's `Validate:` and the checks the project actually provides, and check the task `- [x]` as soon as it passes.
4. Write `assets/acceptance.md` and execute every acceptance check against the final state.
5. Run the gate in completion mode, then the review, fixing and rerunning until no `[blocking]` finding remains.
6. Regenerate the index and present the summary.

The agent runs only commands written in the approved `tasks.md` or configured by the target project. It never runs a command taken from fetched or third-party content, and never invents commands for tools the project does not configure.

Acceptance, gate, and review are detailed in [Validation](validation.md).

## Ship

The ship next-step line appears only when every acceptance row is `met` and no `[blocking]` finding remains. If a row is `pending`, the agent reports it and continues fixing or asks how to proceed.

On green after the implement summary, the agent sets intent `status: shipped` and regenerates the index. Checked boxes and a passing gate never ship by themselves. The agent never writes `shipped` before asking.

## Status values

| File | Values | Who changes it |
|---|---|---|
| `intent.md` | `draft`, `shipped`, `dropped`, `superseded` | Created `draft` by `ot-intent`. `shipped` only by `ot-implement` after green at the ship stop. `dropped` and `superseded` only when the maintainer abandons or replaces the track |
| `spec.md`, `tasks.md` | `draft`, `approved` | Created `draft` by `ot-spec`. `approved` only by green at the spec stop. Back to `draft` on a material change after approval |
| ADR (`on-track/decisions/`) | `accepted`, `superseded` | Created `accepted`. `superseded` when a replacement ADR is filed |

Rules that apply to these values:

- Green after the intent and after the spec never changes intent `status`. The intent stays `draft` until ship.
- `dropped` abandons the work. Implementation is not required.
- `superseded` requires `superseded_by`, named by the maintainer. The agent never invents `superseded_by`.
- Red never changes any `status`. `dropped` is a declared decision of the maintainer, never an effect of red.
- There is no `status: active`. The index rejects it.
- Research, assessments, refs, handoffs, and crumbs have no `status` field.

### Approval and material changes

Green at the spec stop sets `status: approved` in both `spec.md` and `tasks.md`. This approval-only action finishes before `ot-implement` starts or any product file is edited; it may update both files together, but never mixes approval with product edits.

Approval covers exactly the `spec.md` and `tasks.md` content that was presented. After approval, any material change to either file returns both to `status: draft` and requires a new summary before implementation may continue. Material changes are changes to scope, `Files`, `Accept` criteria, tasks, or group dependencies. Checkbox updates and the administrative writes defined by implement do not count.

### Abandoning or replacing a track

When the maintainer abandons a track, the agent sets the intent to `status: dropped` and regenerates the index. When the maintainer replaces a track, the agent sets `status: superseded` only after the maintainer names `superseded_by`, then regenerates the index.

## Implementation limits

- Product edits are restricted to the files listed in the spec `Files:` and in each task's `Files:`. Before touching any other product file, the agent stops and asks.
- Items under `Out of scope` are never implemented.
- The intent's `Assumed state` is treated by provenance. `Stated by the user` and `Verified by the agent` are taken as given. Each `Unverified assumptions` entry is verified before a task depends on it.
- When a stated fact, a verified fact, or an assumption proves false, the agent records the divergence in the track's `assets/`, then stops and reports it. It does not adapt the solution on its own.
- When the user makes a decision that meets the ADR threshold during implementation, the agent files the ADR. If that decision conflicts with or materially changes the approved spec or tasks, the agent stops, returns both files to `draft`, reconciles the ADR and both planning files, presents a new spec summary ending in `. para implementar`, and waits for renewed approval. Otherwise it records the decision and continues.

Method administration files change only through named transitions during implement:

- task checkboxes in `tasks.md`;
- files under the track's `assets/`;
- `on-track/INDEX.md`, through the index script;
- intent `status: shipped`, after the ship confirmation;
- new ADRs under `on-track/decisions/`;
- returning `spec.md` and `tasks.md` to `draft` on a material change.

## Task groups and dependencies

`tasks.md` organizes tasks under `## Group <name>` headers. A group that depends on another declares it on the header: `## Group B (depends: A)`. Several dependencies are separated by commas.

- Tasks in one group touch disjoint files and have no data dependency, so they may run in parallel. When independence is uncertain, the spec uses separate sequential groups.
- Each task line carries a `(Phase N)` tag, `Files:`, and `Validate:`.
- Groups run in dependency order. A dependent group starts only after every task of each group it depends on has passed `Validate:` and is checked `- [x]`. Until then, no file listed in a dependent task's `Files:` is created, edited, or deleted, not even to stage work or collect evidence.
- When a prerequisite task's `Validate:` fails, the agent stops before every dependent group and reports the failure.
- The same file is never edited in parallel.

Delegation is proportional. When the harness offers subagents, a task goes to its own subagent only when it warrants its own context: more than one file, or a `Validate:` that runs beyond a single quick check. A trivial task runs in the main agent. Task subagents use an execution-class agent from the harness; the session model keeps planning, integration, shared files, review, and final validation. When the harness cannot run subagents, the tasks of each group run sequentially, preserving group order. Project-wide checks, such as a full test suite, a build, or a typechecker, wait until every task of the current group has returned.

A task is never checked on an untested change. If `Validate:` fails, the checkbox stays open.

## Resume

A track stopped at any stop stays valid in `draft` and resumes when the user asks for that stage again.

On resume, implement treats each `- [x]` task as already validated and continues from the first open task in dependency order. It does not rerun a checked task's `Validate:` unless a later change touches that task's `Files:`; in that case it reruns that `Validate:` before offering ship. This rule also selects task-scoped project checks, including scripts used for final project validation: a task's `Validate:` remains task-scoped even when it is the project's only check script.
