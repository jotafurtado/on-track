# Evals: Skill Standards Compliance

**Date**: 2026-09-27

## Executable Runner

Run every deterministic check from the repository root:

```bash
bash evals/run-evals.sh all
```

Run one selector by replacing `all` with its name. Every selector uses a fresh temporary fixture and removes it on exit. No selector reads the archived history under `.archive/on-track/`.

| Selector | Observable Contract | Expected Exit | Result |
|----------|---------------------|---------------|--------|
| `self` | Runner and every published shell script, including the agent-eval runner, shared library, and the Kiro, Claude, and Codex adapters, pass `bash -n`; repository validation does not mask gate failures; the agent-eval runner reports `prerequisite-unavailable` for all ten selectors without invoking any CLI when the harness executable is missing, and rejects an unknown harness or unsupported effort before launch; with a stand-in CLI per harness every scenario is staged under that harness's native skill directory with the canonical prompts plus only the location hint; deterministic native-event fixtures show that incomplete streams, failed tool calls, batched approval and product edits, and shell mutation gaps never pass absence or ordering; new single-turn fixtures cover direct routing, compound requests, and artifact thresholds, including incomplete evidence that cannot prove unchanged method paths while durable violations still fail | 0 | PASS |
| `init` | Empty target receives the canonical tree; legacy trees and managed blocks fail before any target write, preserve existing bytes, and report both messages when both exist; reruns are byte-identical; outdated managed blocks refresh without changing surrounding bytes; malformed markers fail before tree creation; symlink targets remain symlinked; the managed snippet classifies each request part before allocation and scopes approval to the Highway and names neither `decisions.md`, `plan.md`, nor `spec/`; the init skill and command carry no conformance or normalization text and no track-migration directory | 0 | PASS |
| `index` | Valid artifacts and citation links appear in deterministic tables; track phase is derived as `intent`, `spec`, `implement N/M`, or `-`, with malformed phase frontmatter tolerated; the default intent fixture is `draft`; handoffs sort by captured instant; a handoff with `## Next actions` is accepted; `status: active`, offset or minute-precision handoff names, offset `captured` values, and P0/P1/First-next-action headings each fail with an objective message and leave `INDEX.md` unchanged; a handoff without `## Next actions` is rejected; orphan tracks, dangling citations/replacements, a loose `tracks/<id>.md` as intent replacement, malformed flow lists, invalid handoff timestamps, and more than three active handoffs fail without changing INDEX.md | 0 | PASS |
| `approval` | Completion remains the default and requires approved artifacts and closed tasks; structure mode accepts draft/open tracks; unknown modes fail; a root `plan.md` and ungrouped tasks fail with their objective messages | 0 | PASS |
| `install` | Default and custom agents/Claude directories contain seven resolving `ot-*` skill links, seven command files, and no `shared` link; every installed `SKILL.md` and owner template is readable through both the `.agents` links and the Claude mirrors; owner and cross-skill sibling resources resolve from the installed directories; installed init (twice, byte-identical), index, and gate run through both locations against disposable valid, open-task, and unapproved tracks; a broken installed sibling fails at the affected location. The check is structural and executable for the installed layout only: it needs no model and does not claim behavior for any unnamed harness that reads `.agents/skills` | 0 | PASS |
| `resources` | Only the init skill and init script retain the legacy package literal; no old command identifiers remain in the package or in either README, and exactly seven `ot-*` skill directories and seven `ot-*.md` command files exist; every owned script and template has exactly one owner guidance reference; removed init templates are absent; every skill states the skill-relative path resolution rule; `README.md` and `README.pt-BR.md` exist, link to each other, have the same number of second-level headings, embed the three diagrams of their own language, and contain no retired wording, command name, or em dash | 0 | PASS |
| `workflows` | Auxiliary assessment requires conditions not settled by relevant-file reading, with commands, measurement, cross-subsystem evidence, or material counterevidence; reading or one-command facts do not qualify. Research, assessment, and handoff are self-contained, status-free where required, and conform to their schemas; research and assessment carry the slug/same-day collision and inconclusive rules; assessment findings state problem, evidence, consequence, and recommendation | 0 | PASS |
| `refs` | Intent provenance separates user statements, session-verified facts with path or command, unverified assumptions, and access limits; Ref instructions cover inline, pinned pointer, mutable pointer replacement, candidate-hash reuse, persisted duplicate rejection, locator hashes, and unavailable sources; the ref template carries only its type section and no `## Contract` | 0 | PASS |
| `decisions` | Intent, spec, implement, and the managed snippet carry identical ADR qualification text and require a real choice with a rejected alternative plus costly reversal or an essential recorded reason; durability and user preference alone do not qualify; evidence lives only in the `## Evidence` body; material planning-drift approval rules, immutable original ADR content, and `superseded_by` replacement are covered | 0 | PASS |
| `handoff` | Four UTC-seconds handoffs are ordered by captured instant; the oldest is archived, the newest three remain active, and the archive is absent from INDEX; the handoff skill orders its collision check, write, validation, archive, and index steps in that sequence | 0 | PASS |
| `spec` | Structure checks require phases, non-empty phase fields, tasks, per-task fields, and valid unique acyclic groups; intent IDs must match track directories; ungrouped tasks fail with `tasks.md has no group header`; hidden root entries, a root `plan.md`, `decisions.md`, or `spec` (file or directory) fail as entries outside the allowed set, and a directory `spec.md` or file `assets` fails on its type; the spec template names neither `decisions.md` nor `plan.md` | 0 | PASS |
| `flow` | Both routing entry points classify compound parts, operational requests without artifacts, Express changes by five criteria with explicit user overrides, escalation before a criterion-breaking edit, and the sole ADR exception; verified facts participate in the divergence stop, and intent quality pins constraint provenance, risk, proportional content, real questions, binding constraints, and conditional summary warnings; Intent, spec, and implement skills plus the tasks template contain continuous-flow next-step lines, `## Group`, and `(depends:`, and the intent skill does not contain the retired exit line; the implement skill states proportional delegation, resume from the first open task, the divergence stop, and that a dependent group's Files are not created, edited, or deleted before every prerequisite task has passed Validate and is checked, with a stop on a failed prerequisite, and names the code-review ref as provenance that the consuming project does not need; question checks require investigation first, blocking-only Highway questions with recommendations, a single intent round of four, repeated spec rounds until resolution, delegated decisions and veto summaries, and Off Road consultation that ends at spec approval; the crumb contract states `files` as a YAML block list; the managed block and the intent and spec skills state that Off Road adds no field to any artifact and that a new session starts with it off, and templates and the handoff skill stay free of the mode; retired question caps are rejected while the Express three-file criterion stays; review checks require in-scope important fixes, open dispositions for other findings, a review record with severity, finding, location, and fixed/open disposition, and summary counts naming open important findings; the managed block states the no-commit, no-push, no-deploy rule for every lane, and the implement skill restates it at ship | 0 | PASS |
| `active` | No live skill, template, or command file contains `status: active`, and an intent with `status: active` fails the index with `invalid status: active` and leaves `INDEX.md` unchanged | 0 | PASS |
| `frontmatter` | Index and gate reject the same malformed fixtures (unclosed block, duplicate key, indented list line) with the same rule text, a `---` pair below line 1 yields no fields, every index rejection leaves `INDEX.md` byte-identical, and every frontmatter template fits the canonical subset | 0 | PASS |
| `docs` | When `docs/` exists: English/pt-BR page parity, required frontmatter, resolving relative Markdown links and VitePress navigation, no retired command names or em dashes, legacy slug limited to installation and migration, and no retired technical guide; no page shows an inline `files` list; exactly workflow, support-context, and lanes SVG/PNG pairs per language, no retired SVG names, no root image files, and resolving relative links and image references in pages and in both READMEs. Without `docs/`, prints the SKIP line and succeeds | 0 | PASS |
| `isolation` | A copy of `skills/`, `commands/`, `install.sh`, `AGENTS.md`, `README.md`, `README.pt-BR.md`, and `evals/` without `docs/` or a root `on-track/` passes `run-evals.sh all` | 0 | PASS |

## Behavioral Fixtures

### Init

- Prompt: "Setup on-track here."
- Expected files: `on-track/{research,refs,handoffs/archive,assessments,decisions,tracks}/`, `on-track/INDEX.md`, and one managed block in `AGENTS.md`.
- Expected exit: 0, twice in a row (idempotent).
- An outdated managed block between user text is replaced while the surrounding bytes remain unchanged. Begin-without-end, duplicated, or out-of-order markers exit 1 without writing or creating the tree; a symlinked `AGENTS.md` remains a symlink. A pre-existing `specs/` directory is left untouched.

### Index

- Prompt: "Regenerate the index."
- Expected tables: tracks, refs, research, assessments, decisions, and active handoffs; active handoffs are ordered by `captured` instant.
- Track columns are `track`, `status`, and derived `phase`. Draft tracks show `intent` without root spec/tasks regular files, `spec` with only one file or either file not approved, and `implement N/M` with both approved. Counts follow the gate's exact lowercase task-line syntax, including open, fully checked, and zero-task fixtures. Shipped, dropped, and superseded tracks show `-`.
- Phase fixtures cover spec-only, tasks-only, either approval still draft, non-regular spec/tasks paths, and spec frontmatter that is unclosed, duplicated, invalid, absent, or missing status. These phase inputs never introduce an index validation failure.
- Valid fixtures: inline refs with and without a blank separator, pinned pointer, mutable pointer and replacement, multi-source research, assessment, accepted decision, superseded decision with replacement, superseded intent pointing at `tracks/<id>/intent.md`, and active handoff. UTC-seconds handoffs with `## Next actions` are accepted; a handoff without that heading is rejected without changing `INDEX.md`. Two unchanged runs are byte-identical; archived handoffs are absent.
- Failure fixtures include an invalid research artifact after a valid index: the command exits 1, preserves `INDEX.md` byte-for-byte, reports that the index was not updated, and removes its temporary file. Cross-link and handoff integrity failures name the affected artifact and rule. A loose `tracks/<id>.md` does not satisfy an intent `superseded_by`.

### Approval Gate

- Prompt: "Check if the track is done."
- Approval selector: draft intent with approved closed spec+tasks exits 0; a root `plan.md`, ungrouped tasks, unapproved spec/tasks, and open tasks each exit 1. Structure mode accepts the same draft status and open task state; unknown mode and mismatched intent id fail.

### Spec Cycle

- Prompt: "Approve this spec."
- Required file: track-root `spec.md` with at least one `### Phase` and non-empty `Done:`, `Files:`, and `Accept:` in each phase.
- Failure fixtures: approved tasks without `spec.md`, `spec/` without root `spec.md`, no phase, empty phase `Accept:`, no tasks, a task missing `Validate:`, unknown/self/duplicate group dependencies, dependency cycles, task before first group, tasks with no group header, mismatched intent ID, root `plan.md`, root `decisions.md`, a `spec` file or directory, hidden root entries `.notes` and `.DS_Store`, a regular file `assets`, and a directory `spec.md`.

## Recorded Run

`run-evals.sh all` completed with all sixteen selectors passing on 2026-10-13 against package state `HEAD f9d95ad` plus the uncommitted multi-harness runner changes (see Readiness Matrix). That includes the strengthened `install` selector (generic `.agents` links and Claude mirrors, default and custom layouts, installed init twice, index, and gate) and the native-event regression fixtures. It needed no authenticated agent, and the result describes installation and resource compatibility only, not real-agent behavior of any unnamed `.agents` consumer.

## Agent Behavior Evals (Optional)

`evals/run-agent-evals.sh` runs real agent sessions through Kiro, Claude Code, or Codex against disposable target repositories to check the continuous-flow protocol. It is maintainer-only, local, and explicit: `run-evals.sh all` never calls it, and none of its results affect the deterministic suite. Each run consumes the selected harness's model quota. A runner exit code of 0 is not package readiness (see Readiness Matrix).

```bash
bash evals/run-agent-evals.sh <selector> [--harness kiro|claude|codex] [--model MODEL] [--effort EFFORT] [--timeout SECONDS] [--keep-dir DIR]
```

Selectors: `compat`, `revision`, `approval`, `red-signal`, `failed-validation`, `material-change`, `resume`, `express-change`, `compound-request`, `artifact-threshold`, `all`.

### Prerequisites

- `jq`, `rsync`, `shasum`, and `git`.
- `kiro` (default): a Kiro CLI on `PATH` (or at `KIRO_CLI`) that is logged in; `kiro-cli whoami` must exit 0. Sessions run with `--trust-all-tools` inside the disposable workspace.
- `claude`: a Claude Code CLI on `PATH` (or at `CLAUDE_CLI`) that is logged in; `claude auth status` must report `loggedIn`. Sessions run with `--permission-mode dontAsk`, an explicit tool allow-list, `--setting-sources project,local`, `--strict-mcp-config`, and Claude Code's native sandbox enabled (`autoAllowBashIfSandboxed`, `allowUnsandboxedCommands: false`), so shell writes outside the workspace are denied.
- `codex`: a Codex CLI on `PATH` (or at `CODEX_CLI`) that is logged in; `codex login status` must exit 0. Sessions run `codex exec --json` with `sandbox_mode="workspace-write"` and `approval_policy="never"`; they are persisted (never `--ephemeral`, never `--last`, never a sandbox bypass).
- A missing executable, missing tool, or failed login check reports all selected scenarios as `prerequisite-unavailable` before any CLI is started. Each invocation is independent: one harness's prerequisite says nothing about another.
- Run the suite only on a machine where these permissions are acceptable. The disposable repository does not sandbox the whole machine: Kiro runs with all tools trusted, and Claude and Codex confine shell writes through their own sandboxes only.

### Configuration

| Input | Flag | Environment default | Default |
|-------|------|---------------------|---------|
| Harness | `--harness` | none | `kiro` |
| Model | `--model` | `ON_TRACK_AGENT_MODEL` | Harness default |
| Effort | `--effort` | `ON_TRACK_AGENT_EFFORT` | Harness default |
| Per-turn timeout in seconds; a scenario is bounded by turns times this value | `--timeout` | `ON_TRACK_AGENT_TIMEOUT` | 900 |
| Kiro executable | none | `KIRO_CLI` | `kiro-cli` |
| Claude Code executable | none | `CLAUDE_CLI` | `claude` |
| Codex executable | none | `CODEX_CLI` | `codex` |
| Codex home for local session evidence | none | `CODEX_HOME` | `~/.codex` |
| Diagnostic directory | `--keep-dir` | none | temporary directory |

Supported efforts: Kiro and Claude Code `low medium high xhigh max`; Codex `none minimal low medium high xhigh max`. An unsupported effort is a usage error (exit 2), never silently replaced. When no model or effort is given the harness default applies, and the model and effort the harness actually reported are recorded per turn in `turns.jsonl` (`observed`) where the harness exposes them.

### Isolation

Each scenario gets a fresh workspace: `on-track-init.sh`, the fixture overlay from `evals/agent/fixtures/<scenario>/workspace/`, `on-track-index.sh`, a copy (never a symlink) of `skills/ot-*` under the selected harness's native skill directory (`.kiro/skills/`, `.claude/skills/`, or `.agents/skills/`), and a baseline git commit with signing disabled. No installed skill or command is required and the archived history under `.archive/on-track/` is never read. The `compat` workspace is an empty git repository.

The canonical turn prompts in `evals/agent/fixtures/<scenario>/turns/` name no harness. The runner stages a copy per scenario and adds only the sentence `The skill is available under <native dir>/skills/.` after the first `in this repository.`; user decisions and continuation inputs such as `.` stay byte-identical. `red-signal` reuses the approval fixture and stages `x` as its second turn. Prompts do not paste skill bodies or force a tool choice.

The evaluated package must be what the agent loads, so each adapter records `skillLoads` per turn: skill reads or loads whose path resolves to the staged workspace directory are `staged`, and anything else (for example a global copy) is not. Every skill-driven scenario asserts that the skill under test was loaded from the staged location; without that machine-verifiable evidence the scenario is `inconclusive`.

The workspace is disposable, but each harness still loads the maintainer's inherited configuration (for example Kiro steering and skills under `~/.kiro/`, Claude Code user memory and authentication, Codex `~/.codex/config.toml` and `AGENTS.md`). That configuration can influence agent behavior and is not controlled by the runner; record it when comparing runs across machines. Secrets are never copied into diagnostics.

### Adapters

Each adapter is `evals/agent/<harness>-adapter.sh --workspace DIR --turns-dir DIR --out DIR [--model MODEL] [--effort EFFORT] [--timeout SECONDS]`. It runs the `turn-NN.txt` files in order in one persisted native session; a turn that does not succeed stops the sequence. Shared helpers (checkpoints, deadline, coverage, ordering) live in `evals/agent/lib.sh`.

| Harness | Turn 1 | Later turns | Native identity |
|---------|--------|-------------|-----------------|
| Kiro | `kiro-cli chat --output-format stream-json --trust-all-tools` | `--resume-id <session id>` | `sessionId` from the stream |
| Claude Code | `claude "<prompt>" -p --output-format stream-json --verbose` plus the permission, setting-source, and sandbox flags above | `--resume <session id>` | `session_id` from the `result` event |
| Codex | `codex exec --json -C <workspace>` plus the sandbox and approval config above | `codex exec resume <thread id> --json` | `thread_id` from `thread.started` |

Claude Code normalizes `Read`, `Glob`, `Grep`, `Edit`, `Write`, `MultiEdit`, `NotebookEdit`, `Bash`, `Task`/`Agent`, and `Skill` tool calls, correlating each call with its `tool_result` and recording the enclosing call of subagent events. Codex normalizes `command_execution` and `file_change` items. Codex stdout omits patch content, so the adapter also reads the thread's rollout file under `$CODEX_HOME/sessions` (read-only, outside the workspace) for each turn's file-change content and the observed model, effort, approval policy, and sandbox; when it is missing, content-dependent assertions stay `inconclusive`. Only `command_execution` and `file_change` carry action coverage for Codex; any other tool item is recorded as `other` and makes the turn's coverage incomplete.

Kiro also normalizes native `disclose_context` skill loads from completed structured source ids/URIs, scope, and origin; disclosure prose or a name alone cannot prove that the staged package was loaded. `rawInput.text` is preserved as new file content. Calls without a recognized native kind or tool id make coverage incomplete.

Evidence under `--out`:

- `turns.jsonl`: one record per turn with `harness`, `outcome` (`success`, `error`, `timeout`, `auth-failure`, `not-run`), `exitCode`, `sessionId`, `checkpoint`, `ordered` (the stream had its start and completion events), `unparsedLines`, `eventCount`, `actionCount`, `coverage` (`complete` plus `reasons`), `skillLoads`, `usage` (tokens and cost where reported, otherwise `null`), `credits` (Kiro only), and `observed` (model, effort, permission or sandbox settings, CLI version, when the harness reports them). Unknown usage stays `null`, never zero.
- `turn-NN.events.jsonl` and `turn-NN.stderr`: raw native output; Codex also keeps `turn-NN.rollout.jsonl`, that turn's slice of the local session file.
- `turn-NN.actions.jsonl`: tool calls with `seq` (stream index where the call started), `endSeq` (where its result arrived, or `null`), `toolCallId`, `parent`, `kind` (`read`, `edit`, `execute`, `agent`, `skill`, `other`), `tool`, workspace-relative `paths`, shell `command`, raw `input`, `written` (text written, when known), native tool-result `output` (text fragments, not assistant prose), and final `status`.
- `checkpoints/turn-NN/` and `checkpoints/turn-NN.manifest`: workspace snapshot and sha256 manifest after each turn, excluding `.git`, `.kiro`, `.claude`, and `.agents`; `turn-00` is the baseline. Other hidden product files, including the resume marker, stay visible.

Ordering is proven only when the first action completed before the second started (`endSeq` before `seq`). Batched or concurrent actions get no invented order: a patch that approves both artifacts and edits the product in one batch is `inconclusive` for the approval order. Absence assertions (no product edit action, no edit of a dependent file) pass only when the turn's coverage is complete, that is, the stream finished, every call has a result, no line was unparsed, and every nested agent was observed. A recorded violation fails regardless of coverage, and final-state checks are never relaxed.

Agent response text stays only in the raw events. No assertion reads it.

### Scenarios

Verdicts use only checkpoints, frontmatter, task checkboxes, command results, and recorded actions. A product path is any path outside `on-track/`, `.kiro/`, `.claude/`, `.agents/`, and `.git/`.

| Selector | Fixture | Assertions |
|----------|---------|------------|
| `compat` | Turn 1 gives the token in `fixtures/compat/expected-token` and forbids file changes; turn 2 resumes and asks for `token.txt` with that token | Records `capability.json` as `supported` (same session id and the token written in turn 2), `unsupported`, `timeout`, or `auth-failure` |
| `revision` | Intent for `greeting.txt`; turn 1 runs the spec skill, turn 2 is a revision | `spec.md` and `tasks.md` are `draft` after both turns, no product change at either checkpoint, no product edit action in turn 2, no checked task, intent not `shipped` |
| `approval` | Same intent; turn 1 runs the spec skill, turn 2 is `.` | Both artifacts `draft` with no product change after turn 1 and `approved` after turn 2; the edit actions that write `status: approved` to both precede the first product edit action |
| `red-signal` | Reuses the approval intent and spec prompt; turn 2 is `x` | Both planning artifacts remain `draft` after both turns; no product change at either checkpoint or product edit action in turn 2; no checked task; intent remains `draft`; no track file from turn 1 is missing after turn 2 |
| `failed-validation` | Approved track whose Task 1 Validate, `scripts/check-greeting.sh`, always exits 1; Task 2 in a dependent group | The Validate command ran; both tasks stay open; `farewell.txt` is absent and no edit action targets it; the script is unchanged; intent not `shipped`; `assets/acceptance.md` is absent or keeps a `pending` row, so ship was not offered; the completion gate rejects the track |
| `material-change` | Approved `greeting.txt` track; the implement turn carries a final decision to deliver `greeting.json` instead | Both artifacts return to `draft`, no product change or product edit action, no checked task, intent not `shipped` |
| `resume` | Approved track with Task 1 checked and Tasks 2 and 3 open in dependent groups; `scripts/validate-alpha.sh` writes a file marker and emits `FTAI_VALIDATION_EXECUTED:resume:alpha` when run | The file and emitted execution marker are absent; reading the unchanged script source does not count as execution, and opaque or suppressed referenced output is inconclusive; `alpha.txt` is unchanged; Task 1 stays checked; the first product edit action targets `beta.txt` |

| `express-change` | Managed-block request to change `greeting.txt` from `hello` to `hello world`, verified by an existing script; no skill or track requested | Final greeting is `hello world`; exactly one new crumb has a UTC timestamp and kebab-case slug, `created`, `files` as a YAML block list listing `greeting.txt`, and Request, Changes, and Verification headings; an inline `files` list fails; only the crumb and a previously missing crumbs folder and its `.gitignore` may change under `on-track/`; a missing crumb or any other changed method path fails; no-op or incomplete evidence is inconclusive |
| `compound-request` | Managed-block request to run a report with execution markers and rename a public `--name` CLI flag to `--recipient` | File marker or native emitted marker proves report execution; exactly one new intent track, no `assets/` entry or report-as-asset reference, no `spec.md`; no product change except the explicitly excluded report marker, and no edit action targeting `scripts/greet.sh` |
| `artifact-threshold` | Explicit `ot-intent` request to append greetings to a plain text root log, with one line per greeting | Staged `ot-intent` load; exactly one new intent containing `Verified by the agent`, `From the user`, and `Proposed by the agent` headings; no assessment or decision file and no product change or edit action |

`express-change` was `direct-change` before 2026-11-11.

`material-change` delivers the decision in the same turn that starts implementation, before any task begins. It approximates a decision made mid-implementation with one turn, which keeps cost and model variance low; a decision arriving after a task has started is not exercised.

`revision`, `approval`, `red-signal`, and `material-change` run only after `compat` reports `supported` in the same invocation; otherwise they report `inconclusive` (or `prerequisite-unavailable` on `auth-failure`) with the compat reason.

### Results

`red-signal` has one recorded real-agent run on Claude Code and Codex (see Signal and Crumb Scenario Runs). Stand-in checks validate runner behavior only.

The earlier `express-change` contract, `compound-request`, and `artifact-threshold` each have one recorded real-agent run on Claude Code and Codex (see Single-turn Scenario Runs). The crumb assertions of `express-change` have one recorded real-agent run on each of those two harnesses (see Signal and Crumb Scenario Runs). Deterministic stand-in CLI and native-event checks validate runner logic and evidence handling only; the new real-agent observations are separate from the existing baseline and readiness matrices.

Each scenario prints `RESULT: <scenario> <classification>: <reason>`, followed by `SUMMARY:` with counts.

- `pass`: every assertion held.
- `fail`: at least one durable-state or recorded-action assertion did not hold.
- `inconclusive`: unsupported continuation, timeout, a turn error, the model not reaching the state under test, no machine-verifiable load of the staged skill, or an order or absence assertion without reliable evidence (incomplete or uncovered action stream, product change made outside an edit action, approval written outside an edit action, batched or concurrent edits, missing patch content).
- `prerequisite-unavailable`: missing harness CLI, failed login check, or missing tool, checked before any scenario so none runs; or an authentication failure during a turn, which classifies only that scenario.

Exit code: 0 when no scenario failed, 1 when any scenario failed, 2 on a usage error. All classifications are non-blocking for `run-evals.sh all`. Exit code 0 also results from `inconclusive` and `prerequisite-unavailable` and therefore never means readiness.

### Diagnostics

Without `--keep-dir`, passing scenario directories are removed and non-passing ones are kept under a temporary root printed as `DIAGNOSTICS ROOT:`; the root is removed when everything passed. With `--keep-dir DIR`, every scenario directory is kept under `DIR/<harness>/<scenario>/`, so runs of different harnesses never overwrite each other. Each holds `turns/` (the staged prompts), `workspace/`, `evidence/`, `adapter.log`, `assertions.log` (one `PASS`, `FAIL`, or `INCONCLUSIVE` line per assertion), and `result.json` (which names the harness). The runner prints `HARNESS: <harness>` before any result. Earlier runs that stored diagnostics under `DIR/<scenario>/` predate this layout.

### Recorded Agent Run

2026-10-02, kiro-cli 2.27.0, Kiro default model and effort, 900 s per turn, about 6.5 credits in total.

| Selector | Result | Note |
|----------|--------|------|
| `compat` | pass | Headless `--resume-id` continuation supported |
| `revision` | pass | 9 assertions |
| `approval` | pass | Approval writes at seq 10 and 11, first product edit at seq 26 |
| `failed-validation` | fail | The agent kept both tasks open and recorded the divergence, but created `farewell.txt` for Task 2 before Group A passed |
| `material-change` | pass | 6 assertions |
| `resume` | pass | First product edit targeted `beta.txt`; `validate-alpha.sh` not rerun |

2026-10-03, kiro-cli 2.27.1, Kiro default model and effort, 900 s per turn, after the implement skill gained the dependent-group rule (step 4). Two `failed-validation` runs, about 1.95 credits in total.

| Run | Selector | Result | Credits | Note |
|-----|----------|--------|---------|------|
| 1 | `failed-validation` | pass | 1.09 | 9 assertions; `farewell.txt` absent and no edit action targeted it; both tasks open |
| 2 | `failed-validation` | pass | 0.87 | 9 assertions; `farewell.txt` absent and no edit action targeted it; both tasks open |

### Single-turn Scenario Runs (2026-11-10)

The lead agent ran each new scenario once on Claude Code and Codex against the current working tree, using `bash evals/run-agent-evals.sh <scenario> --harness <codex|claude> --timeout 600 --keep-dir <dir>`, without `--model` or `--effort`; both used their CLI default configuration. Retained `evidence/turns.jsonl` records Codex CLI `codex-cli 0.167.0`, model `gpt-6.1-sol`, effort `medium`; Claude Code CLI `2.1.322`, model `claude-haiku-5-5`, with no observed effort value. Kiro was not run. One run per cell measures no variance, and these observations are not a package readiness result or an extension of the baseline/readiness matrices.

| Harness | Scenario | Result | Recorded reason |
|---------|----------|--------|-----------------|
| Codex | `direct-change` | pass | 2 assertions passed |
| Codex | `compound-request` | pass | 7 assertions passed |
| Codex | `artifact-threshold` | pass | 8 assertions passed |
| Claude Code | `direct-change` | pass | 2 assertions passed |
| Claude Code | `compound-request` | pass | 7 assertions passed |
| Claude Code | `artifact-threshold` | pass | 8 assertions passed |

Results were checked directly in the six `result.json` files retained through `--keep-dir`, outside the package; each records empty requested model/effort fields and `timeoutSeconds: 600`. The retained directories also held assertions, adapter logs, native evidence, and workspaces.

### Signal and Crumb Scenario Runs (2026-11-11)

The lead agent ran `express-change` (crumb assertions) and `red-signal` once on Claude Code and Codex against the working tree, using `bash evals/run-agent-evals.sh <scenario> --harness <codex|claude> --timeout 600 --keep-dir <dir>`, without `--model` or `--effort`. Retained `evidence/turns.jsonl` records Codex CLI `codex-cli 0.167.0`, model `gpt-6.1-sol`, effort `medium`; Claude Code CLI `2.1.322`, model `claude-opus-5-5`, with no observed effort value. Kiro was not run. One run per cell measures no variance, and these observations are not a package readiness result or an extension of the baseline/readiness matrices.

| Harness | Scenario | Result | Recorded reason |
|---------|----------|--------|-----------------|
| Codex | `express-change` | pass | 2 assertions passed: one well-formed crumb and no other method path changed; greeting holds `hello world` |
| Codex | `red-signal` | pass | 12 assertions passed, after `compat` reported `supported` |
| Claude Code | `express-change` | pass | 2 assertions passed: one well-formed crumb and no other method path changed; greeting holds `hello world` |
| Claude Code | `red-signal` | pass | 12 assertions passed, after `compat` reported `supported` |

Results were checked directly in the four `result.json` files and `assertions.log` files retained through `--keep-dir`, outside the package; each records empty requested model/effort fields and `timeoutSeconds: 600`.

### Rename Scenario Runs (2026-11-11)

After the package was renamed to On Track Method (`on-track/` tree, `ot-*` skills and commands), the lead agent ran `express-change` and `red-signal` once on Claude Code and Codex against the working tree, using `bash evals/run-agent-evals.sh <scenario> --harness <codex|claude> --timeout 600 --keep-dir <dir>`, without `--model` or `--effort`. Retained `evidence/turns.jsonl` records Codex CLI `codex-cli 0.167.0`, model `gpt-6.1-sol`, effort `medium`; Claude Code CLI `2.1.322`, model `claude-opus-5-5`, with no observed effort value. Kiro was not run. One run per cell measures no variance, and these observations are not a package readiness result or an extension of the baseline/readiness matrices.

| Harness | Scenario | Result | Recorded reason |
|---------|----------|--------|-----------------|
| Codex | `express-change` | pass | 2 assertions passed |
| Codex | `red-signal` | pass | 12 assertions passed, after `compat` reported `supported` |
| Claude Code | `express-change` | pass | 2 assertions passed |
| Claude Code | `red-signal` | pass | 12 assertions passed, after `compat` reported `supported` |

Results were read from the `RESULT:` and `SUMMARY:` lines of each run and from the scenario directories retained through `--keep-dir`, outside the package.

### Crumb Form Scenario Runs (2026-11-11)

After the crumb contract defined `files` as a YAML block list and the `express-change` assertion stopped accepting an inline list, the lead agent ran `express-change` once on Claude Code and Codex against the working tree, using `bash evals/run-agent-evals.sh express-change --harness <codex|claude> --timeout 600 --keep-dir <dir>`, without `--model` or `--effort`. The working tree also held the session-bound Off Road wording and the rule that the method never commits, pushes, or deploys on its own. Retained `evidence/turns.jsonl` records Codex CLI `codex-cli 0.167.0`, model `gpt-6.1-sol`, effort `medium`; Claude Code CLI `2.1.322`, model `claude-opus-5-5`, with no observed effort value. Kiro was not run. One run per cell measures no variance, and these observations are not a package readiness result or an extension of the baseline/readiness matrices.

| Harness | Scenario | Result | Recorded reason |
|---------|----------|--------|-----------------|
| Codex | `express-change` | pass | 2 assertions passed; the crumb wrote `files` as a block list |
| Claude Code | `express-change` | pass | 2 assertions passed; the crumb wrote `files` as a block list |

In both retained workspaces `git rev-list --count HEAD` printed `1`, the fixture baseline: neither agent committed. This is an observation read from the retained directories, not a runner assertion.

### Baseline Matrix (2026-10-13)

Evaluated state, 2026-10-13: `HEAD f9d95ad`. The published package (`skills/`, `commands/`, `install.sh`) is identical to `HEAD` (git tree `skills` and `commands` unchanged, no diff), so the package under test is that commit; the runner, adapters, `lib.sh`, fixture prompts, and `run-evals.sh` are uncommitted working-tree changes. Diagnostics are retained outside the package under `/tmp/ftai-mh-evidence/`.

Generic installation: `bash evals/run-evals.sh install` and `bash evals/run-evals.sh all` pass (16 of 16 selectors), with no authenticated agent.

CLIs: `kiro-cli 2.28.0`, `claude 2.1.296 (Claude Code)`, `codex-cli 0.159.2`. No `--model` or `--effort` was given, so each harness used its default. Observable settings: Claude Code reported model `claude-haiku-5-5`, permission mode `dontAsk`, no effort field; Codex reported model `gpt-6.1-sol`, effort `low`, approval `never`, sandbox `workspace-write` (from its local rollout file); Kiro reports neither model nor effort in its stream. Inherited configuration (user memory, user-level skills, `~/.codex/config.toml` and `AGENTS.md`, `~/.kiro/` steering) was loaded by each CLI and not controlled; Claude Code user-level settings files were not loaded.

Evidence roots: `matrix-<harness>` is the first full `all` run per harness; `final-*` are single-selector reruns, made only after an oracle fix or to re-check an evidence-gap cell. A passing cell is never repeated. The first matrix ran before the `ftai_shell_may_mutate` heredoc fix (`evals/agent/lib.sh`), which only the `failed-validation` assertion uses; those cells were rerun after the fix, and the verdicts below are the latest per cell.

| Harness | Selector | Verdict | Evidence | Reason |
|---------|----------|---------|----------|--------|
| Kiro | `compat` | pass | `matrix-kiro/kiro/compat` | Session retained across turns; token from turn 1 written in turn 2 |
| Kiro | `revision` | pass | `matrix-kiro/kiro/revision` | 10 assertions |
| Kiro | `approval` | inconclusive | `final-kiro-approval/kiro/approval` (also `matrix-kiro`) | Approval was written with `sed -i` through the shell, not as an edit action, so approval order is not provable |
| Kiro | `failed-validation` | pass | `matrix-kiro/kiro/failed-validation` | 10 assertions |
| Kiro | `material-change` | pass | `matrix-kiro/kiro/material-change` | 7 assertions |
| Kiro | `resume` | pass | `matrix-kiro/kiro/resume` | 5 assertions |
| Claude Code | `compat` | pass | `matrix-claude/claude/compat` | Native session id retained; first-turn token written in turn 2 |
| Claude Code | `revision` | pass | `matrix-claude/claude/revision` | 10 assertions |
| Claude Code | `approval` | pass | `matrix-claude/claude/approval` | 7 assertions; separate completed approval writes precede the product edit |
| Claude Code | `failed-validation` | pass | `final-claude-failed-validation/claude/failed-validation` | 10 assertions, after the heredoc fix (see below) |
| Claude Code | `material-change` | pass | `matrix-claude/claude/material-change` | 7 assertions |
| Claude Code | `resume` | **fail** | `matrix-claude/claude/resume` | The agent reran the checked Task 1 Validate (`sh scripts/validate-alpha.sh`, action seq 57), which `on-track-implement` step 1 forbids unless a later change touched Task 1's Files |
| Codex | `compat` | pass | `matrix-codex/codex/compat` | Native thread id retained; first-turn token written in turn 2 |
| Codex | `revision` | pass | `matrix-codex/codex/revision` | 10 assertions |
| Codex | `approval` | inconclusive | `final-codex-approval/codex/approval` (also `matrix-codex`) | Approval and the product file were changed through a shell command (`sed -i`, `printf >`), not a `file_change` patch, so order is not provable |
| Codex | `failed-validation` | pass | `final-codex-failed-validation/codex/failed-validation` | 10 assertions, after the heredoc fix |
| Codex | `material-change` | pass | `matrix-codex/codex/material-change` | 7 assertions |
| Codex | `resume` | inconclusive | `final-codex-resume/codex/resume` (also `matrix-codex`) | `beta.txt` and `gamma.txt` were created with shell redirects, so the order of the first open task is not provable |

Per harness: Kiro 5 pass, 1 inconclusive; Claude Code 5 pass, 1 fail; Codex 4 pass, 2 inconclusive. All three harnesses loaded the staged skill (`skillLoads` with `staged: true`) in every skill-driven scenario that passed.

**This baseline did not establish package readiness.** Kiro `approval`, Claude Code `resume`, and Codex `approval` and `resume` were blockers at that evaluated state. A runner exit code of 0 did not change that.

Findings behind the non-pass cells:

- `failed-validation` on Claude Code and Codex was first `inconclusive` because a heredoc body that only mentioned `farewell.txt` (an acceptance or divergence note) counted as a possible shell mutation. `ftai_shell_may_mutate` now ignores heredoc bodies that are plain data, but still flags redirects to the path, interpreter heredocs, expanding bodies, and mutations after a heredoc; regression fixtures in the `self` selector cover each. The oracle was not loosened for commands that can mutate the path.
- Kiro and Codex `approval`, and Codex `resume`, are `inconclusive` because those agents write files through shell commands, which carry no per-file mutation record. The design keeps these `inconclusive` rather than inferring order from final files or polling snapshots.
- Claude Code `resume` is a recorded behavior failure of the default model against an explicit instruction, with no oracle gap found. It was not rerun to confirm.

Cost of the runs (Kiro credits; Claude Code `total_cost_usd`; Codex reports tokens only): Kiro about 8.4 credits for the first matrix and 1.9 for the rerun; Claude Code about \$0.08 and \$0.006; Codex token counts are in each `turns.jsonl`.

### 2026-10-14 resume remediation

The matrix above is the retained baseline, not approval of the revised package. Step 5 of `on-track-implement` now selects task-scoped project checks under step 1's resume rule, including scripts used during final project validation. The rule remains unchanged: only a later change to a checked task's Files makes its Validate eligible for reexecution; final spec acceptance checks still run.

The revised implement skill has SHA-256 `edf84d33c281b0863ae4c8ba877d8ab59f131a3b6f75b3767b12c202aa638b64`, matching the staged copy in the evaluated workspace. The default Haiku resume run still violated the rule after the clarification; evidence is `/tmp/ftai-mh-20261014-claude-resume/claude/resume`. That failure is retained, not replaced by a retry.

The explicit configuration `bash evals/run-agent-evals.sh all --harness claude --model sonnet --effort high --keep-dir /tmp/ftai-mh-20261014-claude-sonnet` passed all six selectors. CLI `2.1.299` reported model `claude-sonnet-5-5` and permission mode `dontAsk`; `high` was requested, but the stream did not report an observed effort value. In the resume run, the agent validated the open beta/gamma tasks and final spec acceptance, left alpha unchanged, and did not invoke `validate-alpha.sh`. Native edit actions proved beta was edited before other product files.

This intermediate run is evidence for that explicit Claude configuration, not for the default Haiku model or all Claude models. Cross-harness readiness is established only by the final matrix below.

### Readiness Matrix (2026-10-14)

The final package passed every required surface in the explicit configurations below. `bash evals/run-evals.sh all` passed all sixteen deterministic selectors after integration, including generic `.agents` installation and Claude mirrors, native disclosure provenance, validation-source reads, execution records surviving file-marker deletion, missing/suppressed output, and the unchanged batch/concurrency guards. `bash evals/run-evals.sh docs` also passed after the documentation update.

| Harness | CLI Version | Requested Model / Effort | Observed Model / Effort | Diagnostics Root |
|---------|-------------|--------------------------|-------------------------|------------------|
| Kiro | 2.31.0 | `claude-sonnet-5.5` / `high` | Model and effort not exposed by the stream | `/tmp/ftai-mh-20261014-final-kiro/kiro/` |
| Claude Code | 2.1.299 | `sonnet` / `high` | `claude-sonnet-5-5` / effort not exposed | `/tmp/ftai-mh-20261014-final-claude/claude/` |
| Codex | 0.162.1 | `gpt-6.1-sol` / `high` | `gpt-6.1-sol` / `high` | `/tmp/ftai-mh-20261014-final-codex/codex/` |

| Selector | Kiro | Claude Code | Codex |
|----------|------|-------------|-------|
| `compat` | pass | pass | pass |
| `revision` | pass | pass | pass |
| `approval` | pass | pass | pass |
| `failed-validation` | pass | pass | pass |
| `material-change` | pass | pass | pass |
| `resume` | pass | pass | pass |

Each diagnostics root contains `<selector>/result.json`, `assertions.log`, and native `evidence/` records. All skill-driven scenarios loaded the staged package and had complete action coverage. In the final Codex approval, one patch approved the two artifacts at seq 11/endSeq 12, then a separate product patch began at seq 17/endSeq 18. In Kiro, the two approval actions completed at endSeq 40 and 41 before the product edit started at seq 67. No order inside a batch was inferred.

The final invocations were:

```bash
bash evals/run-agent-evals.sh all --harness kiro --model claude-sonnet-5.5 --effort high --keep-dir /tmp/ftai-mh-20261014-final-kiro
bash evals/run-agent-evals.sh all --harness claude --model sonnet --effort high --keep-dir /tmp/ftai-mh-20261014-final-claude
bash evals/run-agent-evals.sh all --harness codex --model gpt-6.1-sol --effort high --keep-dir /tmp/ftai-mh-20261014-final-codex
```

Evaluated state: `HEAD f9d95ad` plus the uncommitted implementation. The final `spec` skill SHA-256 is `539d45caf9845f4abafa704324b99637dbd6b5a2346d63f6e2d439e07b8a9f56`; the `implement` skill SHA-256 is `edf84d33c281b0863ae4c8ba877d8ab59f131a3b6f75b3767b12c202aa638b64`. Both hashes match the staged copies in all three final runs. The executable/resource/turn fingerprint below is `7fa1bf982a9545bf018c39d2baca51e9751d834b8826042d3bddc42d89350e21`:

```bash
shasum -a 256 skills/ot-*/SKILL.md skills/ot-*/assets/*.md skills/ot-*/scripts/*.sh commands/ot-*.md install.sh evals/*.sh evals/agent/*.sh evals/agent/fixtures/*/turns/*.txt evals/agent/fixtures/resume/workspace/scripts/validate-alpha.sh | shasum -a 256
```

Corrections: task-scoped checks follow the resume rule; approval completes as an approval-only action before product mutation; Kiro structured skill disclosure and native text writes are recognized; the resume fixture's emitted execution record replaces the script-name false positive. The earlier Codex high-effort `resume` failure was an oracle defect: its only reference was `cat scripts/validate-alpha.sh`, not invocation.

No general shell observer was added. DEBUG/startup experiments exposed opaque pipelines/subshells and replaceable hooks, so those experiments did not justify a reliable mutation audit. Shell-only ordering without sufficient native evidence, batched approval/product edits, missing output, and incomplete coverage still remain inconclusive.

Readiness is limited to this package state and these explicit configurations. Earlier Haiku failures and earlier inconclusive runs remain diagnostic history, not approval of default settings or every model. Claude reports permission mode `dontAsk`; Codex reports `workspace-write` and approval policy `never`; Kiro uses its explicit trusted-tool mode. Inherited user configuration remains a limitation as described under Isolation.

### Public skill rename

Current skill and command names use `ot-*`. The readiness matrix, historical skill names, hashes, and fingerprint command above describe the package before this rename; they are retained evidence, not a new live-agent validation of the short names. New agent-eval runs are required to establish a readiness matrix for the renamed package.
