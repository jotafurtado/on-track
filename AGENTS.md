# AGENTS.md - on-track repo

On Track Method (package `on-track`), a lightweight agent-driven SDLC. Binding norm lives in Obsidian, `10 - Projetos/Code/on-track/On Track Method - Fundamentos v1.4.md`. Obsidian holds only the norm. This repo holds the executable: skills, commands, scripts, and templates, all inside `skills/`.

## Map

- `commands/` - slash commands, 1 file per command (`ot-init`, `ot-intent`, `ot-spec`, `ot-implement`, `ot-research`, `ot-assess`, `ot-handoff`)
- `skills/ot-*/SKILL.md` - procedure each command runs
- `skills/ot-init/` - SKILL.md plus `scripts/` (`on-track-init.sh`, `on-track-index.sh`) plus `assets/AGENTS-snippet.md`
- `skills/ot-intent/` - SKILL.md plus `assets/` (`intent.md`, `ref.md`)
- `skills/ot-spec/` - SKILL.md plus `scripts/on-track-gate.sh` plus `assets/` (`spec.md`, `tasks.md`, `decisions.md`)
- `skills/ot-assess/`, `skills/ot-research/`, and `skills/ot-handoff/` - each owns its SKILL.md and artifact template; `skills/ot-implement/` owns SKILL.md only
- `openspec/` - local-only maintainer specs and change history; ignored by Git, not part of the published package
- `docs/` - public documentation site source: English at the root, pt-BR mirror under `pt/`, VitePress config under `.vitepress/`, images under `images/`; `README.md` is the short user entry point in English, with `README.pt-BR.md` as its Brazilian Portuguese mirror
- `.archive/` - frozen history of how the package was first built; nothing live reads it
- `.github/workflows/docs.yml` - builds the VitePress site and publishes it to GitHub Pages (`https://jotafurtado.github.io/on-track/`) on every push to `main` that touches `docs/`
- `evals/` - the self-contained maintainer eval suite (`run-evals.sh`, `evals.md`) plus the optional Kiro, Claude Code, and Codex agent-eval runner (`run-agent-evals.sh`, `agent/`); not shipped by `install.sh`

Skills run against the target repo `on-track/` tree using scripts and templates bundled in this package. No machine-fixed paths. Only `ot-init` installs anything, through its own script path.

## Rules

- Code in English: folders, files, functions, variables, frontmatter fields.
- User-facing prose in English: commands, skills, error messages, except the continuous-flow next-step lines (`. para continuar com a spec`, `. para implementar`, `. para ship (marca a track como concluida)`).
- Surgical changes: 1 behavior per change, validated in `/tmp` before commit.
- No stubs: a published script must actually run in the test below.
- A live target project is never edited from here. Method changes validate in `/tmp`.
- Each script and template has one owner skill. Cross-skill consumers reference the owner copy via package-relative sibling paths. No `shared` link.
- This repository does not run the method on itself: never run `ot-init` here.

## Install

`install.sh` links every `skills/ot-*` into the harness skills dirs and links `commands/ot-*.md` into the harness commands dir. No `shared` link exists: each skill owns its resources and cross-skill references point at owner copies. Run the eval suite on any machine:

```bash
./evals/run-evals.sh all
```

`init` must be idempotent: run twice with no error and no duplicated blocks in `AGENTS.md`.
