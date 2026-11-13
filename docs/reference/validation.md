---
title: Validation
description: What the index generator checks, the gate in structure and completion modes, acceptance evidence, the implement review, and the package eval suite.
---

# Validation

This page answers what checks the method runs, what makes each one fail, and what the implement review does with its findings. All bundled scripts are local Bash with no network calls.

## Index generator

`skills/ot-init/scripts/on-track-index.sh [repo-root]` reads frontmatter under `on-track/` and writes only `on-track/INDEX.md`. It builds the whole index in a temporary file and replaces `INDEX.md` only when validation reports no errors. Collected artifact-validation errors produce `ERROR:` lines followed by `INDEX not updated: N error(s).`, exit 1, and leave `INDEX.md` unchanged. If `on-track/tracks` is missing, the script exits 1 after a single `ERROR:` line without that final summary. On success it prints `INDEX ok at <path>`.

Every skill that writes an artifact regenerates the index and reports any validation error instead of presenting its result as complete. The table layout is in [Artifacts](artifacts.md#index-md).

The generator fails when:

| Area | Failure |
|---|---|
| Setup | `on-track/tracks` is missing |
| Frontmatter | A block is not closed, a line is not a `key: value` field, or a key repeats |
| Tracks | A track folder has no `intent.md`; the folder name is not `NNN-slug`; `id` or `status` is missing; `id` differs from the folder name; `status` is not `draft`, `shipped`, `dropped`, or `superseded` |
| Citations | A non-empty `research`, `assessments`, `refs`, or `decisions` value is not a `[a, b]` list, contains an empty parsed slug, or names a file that does not exist. Missing or empty fields are skipped |
| Replacement | `superseded` without `superseded_by`; `superseded_by` pointing at itself or at a missing track or ADR |
| Refs | Bad file name; file over 500 KB; missing `captured`, `owner`, or `content_license`; `sha256` not 64 lowercase hex characters; a `status` field; an invalid `type`; an `inline` ref with `source`, `pin`, or `retrieved_at`, or whose `sha256` does not match its normalized `## Source content`; a `pointer` ref without `source`, with both or neither of `pin` and `retrieved_at`, or whose `sha256` is the hash of its `source` locator; a `sha256` that duplicates an earlier ref |
| Research | Bad file name; missing `captured` or `owner`; a `status` or singular `source` field; a missing required heading |
| Assessments | File name not `YYYY-MM-DD-slug.md`; a missing `captured`, `owner`, `scope`, `evaluator`, or `tracks`; a `status` field; `captured` different from the file name date; a missing required heading |
| Decisions | File name not `NNN-slug.md`; a missing `id`, `status`, `date`, or `owner`; `id` different from the file name; `status` not `accepted` or `superseded`; a missing required heading |
| Handoffs | File name not `YYYY-MM-DD-HHmmssZ-slug.md`; `captured` not `YYYY-MM-DDTHH:MM:SSZ` or not the file name instant; a missing `owner` or `focus`; a `status` field; a missing required heading; more than three active handoffs |

A missing or malformed `spec.md` or `tasks.md` never fails the index; it only counts as not approved when the phase is derived. `crumbs/` and `handoffs/archive/` are never read.

## Gate

`skills/ot-spec/scripts/on-track-gate.sh --track NNN-slug [--root DIR] [--mode structure|completion]` is read-only and only reports. The default mode is `completion`. A failed validation stage prints one or more `FAIL:` lines and exits 1; success prints a `PASS` line.

Both modes check:

1. `on-track/tracks/NNN-slug/intent.md` exists and is a file, its frontmatter is valid, and its `id` equals the track name.
2. The track root has no hidden entry and no entry outside `intent.md`, `spec.md`, `tasks.md`, and `assets`. `spec.md` and `tasks.md` must be files. If `assets` exists, it must be a directory; its absence is accepted.
3. `spec.md` and `tasks.md` exist. When a frontmatter block opens on line 1, malformed lines, duplicate keys, and an unclosed block fail. Structure mode does not require an opening block; completion mode additionally requires `status: approved` in each file.
4. `spec.md` has at least one `### Phase` section, and every phase has non-empty `Done:`, `Files:`, and `Accept:` lines.
5. `tasks.md` has at least one task line and at least one `## Group` header, no task before the first header, non-empty `Files:` and `Validate:` on every task, non-empty and unique group names, and dependencies that name existing groups, never the group itself, and form no cycle.

| Mode | Adds | Pass line | Used by |
|---|---|---|---|
| `structure` | Nothing. Approval status and task checkboxes are ignored | `PASS: NNN-slug structure valid` | `ot-spec`, as an internal smoke test before every summary. A failure is fixed before the draft is presented; draft status is not a failure |
| `completion` | `spec.md` and `tasks.md` have `status: approved`, and no task is open (`- [ ]`) | `PASS: NNN-slug cycle intact` | `ot-implement`, after every task is checked and before the review |

Without a completion pass there is no ship.

## Acceptance evidence

After every task passes `Validate:`, implement writes `on-track/tracks/NNN-slug/assets/acceptance.md` as a table:

```markdown
| Criterion | Check | Observed | Result |
|---|---|---|---|
| Outcome: the new landing page is live at /v2 | curl -s -o /dev/null -w '%{http_code}' localhost:3000/v2 | 200 | met |
| Phase 1: hero renders the new copy | open /v2 and read the hero | "Plan less, ship more" shown | met |
```

There is one row for the spec `Outcome` and one row per phase `Accept:` line. Each check runs against the final state and records what was observed. `Result` is `met` or `pending`. Every row must be `met` before ship is offered. The implement summary reports `N/M met (assets/acceptance.md)`.

## Implement review

After the completion gate passes, implement runs a review owned by the package. The procedure is the same in every track and does not depend on any file in the consuming project. Asking for Off Road earlier does not change it.

Principles: catch bugs and edge cases; keep the change maintainable; comment on the code, not the person; skip formatting a linter owns.

Phases:

1. Context from the intent, the spec, and the diff.
2. High-level fit to the spec `Files:` and `Out of scope`.
3. Line by line on the listed files, for correctness, security, and invented answers or unlisted edits.
4. Summary and a decision.

| Severity | Meaning | Disposition |
|---|---|---|
| `[blocking]` | Must fix | Always fixed before ship |
| `[important]` | Should fix | Fixed when the fix stays within the spec `Files:`; otherwise left `open` |
| `[nit]` | Optional | Left `open` |
| `[suggestion]` | Alternative | Left `open` |

After each fix, the agent reruns the `Validate:` of the affected tasks and the acceptance checks of the affected phases, updates `Observed` and `Result` in `assets/acceptance.md`, reruns the completion gate, and reviews again. The loop repeats until no `[blocking]` finding remains. A fix that needs a file outside the spec, or that changes the approved spec, stops and asks; see [Cycle](cycle.md#implementation-limits).

Every finding is recorded in `on-track/tracks/NNN-slug/assets/review.md`:

```markdown
| Severity | Finding | Location | Disposition |
|---|---|---|---|
| [important] | Empty email accepted by the signup form | src/signup.ts:42 | fixed |
| [nit] | Variable name `d` is unclear | src/hero.ts:10 | open |
```

When the review finds nothing, the file holds the header and one row saying so. The implement summary counts `fixed` and `open` findings and names each open `[important]`. To have an open finding fixed, answer yellow at the ship stop. `assets/review.md` is evidence of the review, not an extra gate requirement.

## Package eval suite

The package itself is checked by a deterministic suite that runs installation, resources, and scripts against disposable projects without calling any model: `bash evals/run-evals.sh all` from the package repository root. Optional sessions with real agents exist, but they never approve the package on their own. Selectors, contracts, and results are listed in `evals/evals.md` in the package repository (see [Installation](../getting-started/installation.md) for where the repository lives).
