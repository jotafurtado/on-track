---
description: Generate unified spec.md and tasks.md with parallelism groups, then offer implement continuation.
---

Run the `ot-spec` skill. Track comes from the arguments. Requires `intent.md`. Intent status may stay `draft`. Blocking questions are asked before the summary is presented; deferrable open questions become grouped tasks. Do not invent answers. Output goes to `on-track/tracks/NNN-slug/spec.md` and `tasks.md`. The skill regenerates `INDEX.md`, runs the gate in structure mode, and fixes any reported breakage before presenting the draft. The skill presents a four-bullet summary and ends with `. para implementar`; on `.` it approves the presented version, setting both files to `status: approved`, and chains to the implement skill. `x` stops without changing status; any other reply revises the current stage. A later material change returns both files to `draft`. Do not auto-approve.
