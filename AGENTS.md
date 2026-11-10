# AGENTS.md - fast-track-ai repo

Method `fast-track-ai`, a lightweight agent-driven SDLC. Binding norm lives in Obsidian, `10 - Projetos/Code/fast-track-ai/dot-ai - Fundamentos v1.3.md`. Obsidian holds only the norm. This repo holds the executable: skills, commands, scripts, and templates, all inside `skills/`.

## Map

- `commands/` - slash commands, 1 file per command (`ft-init`, `ft-intent`, `ft-spec`, `ft-implement`, `ft-research`, `ft-assess`, `ft-handoff`)
- `skills/ft-*/SKILL.md` - procedure each command runs
- `skills/ft-init/` - SKILL.md plus `scripts/` (`fast-track-ai-init.sh`, `fast-track-ai-index.sh`) plus `assets/AGENTS-snippet.md`
- `skills/ft-intent/` - SKILL.md plus `assets/` (`intent.md`, `ref.md`)
- `skills/ft-spec/` - SKILL.md plus `scripts/fast-track-ai-gate.sh` plus `assets/` (`spec.md`, `tasks.md`, `decisions.md`)
- `skills/ft-assess/`, `skills/ft-research/`, and `skills/ft-handoff/` - each owns its SKILL.md and artifact template; `skills/ft-implement/` owns SKILL.md only
- `openspec/` - local-only maintainer specs and change history; ignored by Git, not part of the published package
- `docs/` - technical guide and source images; `README.md` is the short user entry point
- `.archive/` - frozen history of how the package was first built; nothing live reads it
- `evals/` - the self-contained maintainer eval suite (`run-evals.sh`, `evals.md`) plus the optional Kiro, Claude Code, and Codex agent-eval runner (`run-agent-evals.sh`, `agent/`); not shipped by `install.sh`

Skills run against the target repo `fast-track-ai/` tree using scripts and templates bundled in this package. No machine-fixed paths. Only `ft-init` installs anything, through its own script path.

## Rules

- Code in English: folders, files, functions, variables, frontmatter fields.
- User-facing prose in English: commands, skills, error messages, except the continuous-flow next-step lines (`. para continuar com a spec`, `. para implementar`, `. para ship (marca a track como concluida)`).
- Surgical changes: 1 behavior per change, validated in `/tmp` before commit.
- No stubs: a published script must actually run in the test below.
- A live target project is never edited from here. Method changes validate in `/tmp`.
- Each script and template has one owner skill. Cross-skill consumers reference the owner copy via package-relative sibling paths. No `shared` link.
- This repository does not run the method on itself: never run `ft-init` here.

## Install

`install.sh` links every `skills/ft-*` into the harness skills dirs and links `commands/ft-*.md` into the harness commands dir. No `shared` link exists: each skill owns its resources and cross-skill references point at owner copies. Run the eval suite on any machine:

```bash
./evals/run-evals.sh all
```

`init` must be idempotent: run twice with no error and no duplicated blocks in `AGENTS.md`.
