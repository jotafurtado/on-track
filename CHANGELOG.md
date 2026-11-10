# Changelog

Notable changes to fast-track-ai are recorded here. Entries describe user and maintainer impact; unreleased work is not assigned a release version.

## [Unreleased]

### Changed

- The generated track table gains a `phase` column (`intent`, `spec`, `implement N/M`, or `-`) beside `status`; consumers that parse the table must account for the extra column.
- Classify compound requests before allocation: operational parts run without artifacts, and bounded reversible changes use a direct lane without a track. Explicit user lane choices prevail; direct work escalates before a criterion-breaking edit, with a qualifying ADR as its only artifact exception.
- Consumer projects must reinstall the skills for the new text and rerun `ft-init` to refresh the managed `AGENTS.md` block.

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
