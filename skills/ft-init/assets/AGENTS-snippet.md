<!-- BEGIN MANAGED BLOCK: fast-track-ai. Installed by ft-init, idempotent block. -->

## fast-track-ai

Active memory lives in `fast-track-ai/`. Read `fast-track-ai/INDEX.md` before looking for a track or supporting artifact; never scan the whole tree for discovery. The generated index lists tracks with their status and phase, refs, research, assessments, decisions, and active handoffs.

Classify each request, splitting compound requests into parts before allocating anything; handle each part in its own lane. The user's explicit choice wins in both directions: naming `ft-intent` or asking for a track or intent selects the full cycle for an edit; asking to do it directly or without a track selects the direct lane.

- **Operational**: running, building, installing, inspecting, or reporting without editing a versioned target-repo file. Execute directly, with no track or artifact; never record it inside a track, including an `assets/` note.
- **Direct change**: all five criteria hold: (1) the request states what to build, with no open question that changes it; (2) at most three files change; (3) no public contract (API, CLI flags, schema, consumed file format), persisted data or migration, security control (authentication, authorization, secrets, permissions), or dependency (add, upgrade, remove) changes; (4) reverting the diff alone undoes it, with no data backfill or external side effect; (5) one existing command or one observable check verifies it. Say in one sentence that the change takes the direct lane, implement, run the check, and report the change and result. Create no track or file under `fast-track-ai/` and do not regenerate the index. The diff and the maintainer's commit are the record; the method never commits on its own. If a criterion stops holding, stop before the edit that breaks it, name the failed criterion, and start the full cycle with `ft-intent`. The sole artifact exception is a qualifying ADR: file only that ADR and regenerate the index.
- **Change**: every other edit, and any edit where a direct criterion is uncertain, uses the full cycle.
- **Research-only / assessment-only**: route to `ft-research` / `ft-assess` without a track.

For the full cycle only, a change starts as `intent.md`. The `ft-intent` skill drafts `intent.md` only. The `ft-spec` skill drafts `spec.md` and `tasks.md`. Intent approval is not required before those files. Full-cycle implementation requires `spec.md` and `tasks.md` with `status: approved`. Research, assess, and handoff may stop after their artifact and index regeneration without drafting an intent. Intents live in `fast-track-ai/tracks/NNN-slug/intent.md`.

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
