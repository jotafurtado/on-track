<!-- BEGIN MANAGED BLOCK: fast-track-ai. Installed by ft-init, idempotent block. -->

## fast-track-ai

Active memory lives in `fast-track-ai/`. Always read `fast-track-ai/INDEX.md` first; never scan the whole tree for discovery. The generated index lists tracks with their status and phase, refs, research, assessments, decisions, and active handoffs.

A change that will be implemented starts as `intent.md`. The `ft-intent` skill drafts `intent.md` only. The `ft-spec` skill drafts `spec.md` and `tasks.md`. Intent approval is not required before those files. No `spec.md` and `tasks.md` with `status: approved` means no implementation. Research, assess, and handoff may stop after their artifact and index regeneration without drafting an intent. Intents live in `fast-track-ai/tracks/NNN-slug/intent.md`.

Continuous flow: intent, spec, and implement end with a four-bullet summary plus a next-step line. `.` (or an affirmative synonym such as "sim", "pode continuar", "yes", "continue") means "understood, proceed" and chains the next skill for the same track without typing a command; any other input is a new instruction to the current skill. `.` never changes intent `status`; intent stays `draft` until the implement ship sets `shipped`.

Supporting artifact locations:

- A ref lives at `fast-track-ai/refs/<slug>.md`.
- Research lives at `fast-track-ai/research/<slug>.md`.
- An assessment lives at `fast-track-ai/assessments/<YYYY-MM-DD>-<slug>.md`.
- A decision lives at `fast-track-ai/decisions/<NNN-slug>.md`.
- A handoff lives at `fast-track-ai/handoffs/<timestamp>-<slug>.md`.

- Track root holds only `intent.md`, `spec.md`, `tasks.md`, and `assets/`. Loose files are forbidden. Auxiliary outputs go under `assets/`.
- Intent stays `draft` until `shipped`, `dropped`, or `superseded`. `dropped` abandons the work; implementation is not required. `superseded` requires `superseded_by`. Do not invent `superseded_by`. Implement owns `shipped` and asks before writing it.

<!-- END MANAGED BLOCK: fast-track-ai -->
