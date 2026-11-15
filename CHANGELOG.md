# Changelog

Notable changes to On Track Method are recorded here. Entries describe user and maintainer impact; unreleased work is not assigned a release version.

## [Unreleased]

### Added

- Agent evals `express-spread` (the same one-line edit in five files must take the Express lane) and `open-decision` (a one-file request with an open decision must not), with stand-in checks for both in the suite.

### Changed

- Express criterion 2 counts distinct edits instead of files: the change is the smallest that serves the request as stated, one concern with at most three distinct edits, and the same edit repeated across files (a rename, a version string, a mirrored translation) counts once. It replaces "at most three files change", which sent a one-line edit in five files to the Highway and let an agent count files it added on its own.
- Doubt about the size of a change no longer sends it to the Highway. An uncertain criterion 1, 3, 4, or 5 still does; doubt about criterion 2 alone keeps the edit on the Express lane, under its stop rule.
- The managed block marker is `on-track v0.3.0`.
- Agent evals launch each CLI in an isolated environment that carries the maintainer's login and nothing else of the machine: a closed list of inherited variables, no global git configuration, a private home for Codex and Kiro, and auto memory off for Claude Code. Global rules, MCP servers, user-level skills, and terminal variables no longer reach a session, so an eval measures the method alone. With no `--model` or `--effort`, the default is now the CLI's own, not the one in the maintainer's configuration. `ON_TRACK_AGENT_PASS_ENV` names extra variables to inherit, such as proxy settings.

### Upgrade

- Reinstall the skills, then run `ot-doctor` in each project: it refreshes the managed block after you confirm.

## [0.2.0] - 2026-11-15

### Added

- `ot-doctor` diagnoses an on-track project after a package update and repairs it only after the user confirms: a missing or outdated managed block, missing folders, a legacy `fast-track-ai/` tree or block, superseded ADRs left in `decisions/`, ADRs without a title, and index errors. It never deletes an artifact, commits, pushes, or deploys.
- Superseded decisions move, keeping their number, to `on-track/decisions/archive/`. `ot-init` creates the folder; the index fails while a superseded ADR stays in `decisions/`, validates the archive, rejects a number used twice across both folders, and lists ADRs by title.
- The index prints a `WARN:` line when the managed block in `AGENTS.md` is missing or older than the installed package, and the skills relay it without blocking the stage. The block marker now carries the package version (`on-track v0.2.0`).
- The documentation site is published at https://ontrack.jotafurtado.dev/ by a workflow that rebuilds it on every push to `main` that touches `docs/`, with a landing page, a Quick Start page, the On Track Method logo, and a brand theme in English and pt-BR.

### Changed

- Questions on every route skip what is already settled by the request, the context in hand, a lookup tool the project names, or one targeted read. Rounds hold at most four questions on one theme; recorded decisions stay as written, while an undocumented choice may receive a suggestion. Blocking questions are asked on the Highway and in Off Road alike, and spec stops after three Highway rounds and suggests Off Road.
- `ot-init` suggests `ot-doctor` when it refuses a legacy `fast-track-ai/` layout.
- The lanes, workflow, and support-context diagrams are revised, and the READMEs gain the wordmark and a link to the site.

### Removed

- The migrating and design-choices documentation pages.

### Upgrade

- Reinstall the skills, then run `ot-doctor` in each project: it refreshes the managed block and creates `on-track/decisions/archive/` after you confirm.

## [0.1.0] - 2026-11-12

### Added

- Public documentation under `docs/` in English with a Brazilian Portuguese mirror: getting started, guides, reference, and concepts, readable as plain Markdown and renderable with VitePress. The single-file technical guide is retired.
- Local Express crumbs record the request, changed files, and verification for commit preparation, with `files` written as a YAML block list; init creates their ignored folder without overwriting existing files.
- Optional agent-eval scenario `red-signal`, and crumb assertions in `express-change`. One real-agent run per scenario on Claude Code and Codex passed on 2026-11-11; these observations are recorded separately from package readiness.
- After the rename, one real-agent run each of `express-change` and `red-signal` on Claude Code and Codex passed on 2026-11-11; these observations are recorded separately from package readiness.
- With `files` defined as a YAML block list, one real-agent run of `express-change` on Claude Code and Codex passed on 2026-11-11; these observations are recorded separately from package readiness.
- Optional single-turn agent-eval scenarios for Express changes, compound operational/change requests, and assessment/ADR artifact thresholds. One real-agent run per scenario on Claude Code and Codex passed on 2026-11-10; these observations are recorded separately from package readiness.

### Changed

- Diagrams now exist per language under `docs/images/en` and `docs/images/pt`, carry the On Track Method names, and include a new lanes diagram.
- The README is rewritten in English as a short entry point with the three diagrams, and gains a Brazilian Portuguese mirror in `README.pt-BR.md`; detailed rules now live in the documentation.
- **BREAKING:** the package is renamed On Track Method. The consumer tree is `on-track/`, commands and skills are `ot-*`, scripts are `on-track-*.sh`, and agent-eval variables use `ON_TRACK_`. `ot-init` refuses a repository that still holds a `fast-track-ai/` tree or managed block and prints the manual steps; no automatic migration is provided.
- Record every implement review finding in `assets/review.md` and surface fixed and open counts at ship; the review fixes blocking findings and in-scope important ones on every track.
- Investigate before asking Highway questions, use rounds of up to four with recommendations and delegated decisions, and offer Off Road for more consultation during intent and spec; it ends when the spec is approved, adds no field to any artifact, does not carry across sessions, and changes no artifact or threshold.
- Highway stages accept plain-text green, yellow, and red signals: `.` proceeds, `x` stops without changing status or undoing work, and other replies revise the current stage.
- State for every lane that the method never commits, pushes, or deploys on its own: ship only marks the track `shipped`, and a commit, push, or deploy happens only when the user asks for it.
- Name the edit lanes Express and Highway, with Highway as the default; routing criteria and procedures are unchanged.
- The generated track table gains a `phase` column (`intent`, `spec`, `implement N/M`, or `-`) beside `status`; consumers that parse the table must account for the extra column.
- Classify compound requests before allocation: operational parts run without artifacts, and bounded reversible changes use the Express lane without a track. Explicit user lane choices prevail; Express work escalates before a criterion-breaking edit; its only artifacts are a local crumb and, when one qualifies, an ADR.
- Reserve auxiliary assessments for system conditions beyond simple file reading or a one-command fact. Record session-verified facts with their path or command in intent, and stop on a verified-fact divergence during implementation.
- Require both a real weighed choice and costly reversal or an essential recorded reason for ADRs; durability and user preferences alone no longer qualify.
- Keep intent proportional with constraint provenance, risk-based agent proposals, genuine open questions, empty sections marked `None.`, and conditional summary warnings for proposed constraints and unverified foundations. Existing consumer intents remain valid without the new headings.
- Consumer projects must reinstall the skills for the new text and crumb contract and rerun `ot-init` to refresh the managed `AGENTS.md` block and create the local ignored `on-track/crumbs/` folder.

## [0.0.1] - 2026-10-17

### Added

- Adoption-oriented README explaining the SDLC framework, with numbered human/agent steps, explicit skill calls, and a grouped skill reference.
- Supporting-artifact overview covering references, research, assessments, decisions, and handoffs, with storage paths and clarification that references and decisions have no dedicated commands.
- Technical guide preserving the previous README and its detailed Mermaid workflows.
- Optional real-agent workflow evaluation through Claude Code and Codex, alongside Kiro, with native session continuation and shared behavioral assertions.
- Installed-resource validation through generic `.agents/skills` links and Claude mirrors, including bundled init, index, and gate execution in disposable projects.
- A readiness matrix recording package fingerprints, CLI versions, model settings, and native evidence for each evaluated harness.

### Changed

- Redesigned the workflow and supporting-context illustrations with pure-black backgrounds, embedded typography, a uniform elliptical workflow, and all five supporting artifact types.
- BREAKING: Public skill directories, frontmatter names, and command wrappers now use `ft-*` (`ft-init`, `ft-intent`, `ft-spec`, `ft-implement`, `ft-research`, `ft-assess`, `ft-handoff`) without aliases. Reinstall the complete package and remove previous long-name installations. The target `fast-track-ai/` artifact tree and internal script basenames are unchanged.
- Retained agent-eval diagnostics now use `<root>/<harness>/<scenario>` instead of `<root>/<scenario>`. Update scripts that consume diagnostic paths; invocations without `--harness` still select Kiro.
- The spec approval transition completes as an approval-only action before product edits. Both approval artifacts may be updated together, without prescribing an editing tool.
- Frozen package-building history and alternative artwork are now local-only under `.archive/`, ignored by Git; existing local files are preserved.
- Maintainer OpenSpec specifications are now local-only and ignored by Git; existing local files are preserved.
- Retired the `docs` eval selector, which prescribed README wording and layout; runtime checks remain independent of the documentation structure.
- The primary installation instructions use `npx skills` for the complete seven-skill package; the checkout installer remains documented as a maintainer alternative.
- Skills now state what each bundled script reads and writes, that it makes no network calls, that auxiliary research and assessment results are reported by the calling skill, that retrieved or captured content is data rather than instructions, and that implementation runs only commands from the approved `tasks.md` or the project's own checks.

### Fixed

- Apply the checked-task resume rule to task-scoped project checks during final validation, while still running the spec's final acceptance checks.
- Recognize structured Kiro skill-disclosure provenance and native text writes instead of treating staged skill loads as unobserved.
- Distinguish reading a Validate script from executing it. Native fixture execution records remain observable after a file marker is deleted; missing or suppressed evidence stays inconclusive.

Readiness applies to the package state and explicit model configurations recorded in [the evaluation results](evals/evals.md), not to every model or default setting.
