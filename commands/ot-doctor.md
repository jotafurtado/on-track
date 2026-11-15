---
description: Diagnose an on-track project and repair it after confirmation.
---

Run the `ot-doctor` skill. It executes `skills/ot-doctor/scripts/on-track-doctor.sh` on the target directory, which changes nothing and lists each finding: a legacy `fast-track-ai` layout, a missing or outdated managed block in `AGENTS.md`, missing folders, a superseded ADR outside `on-track/decisions/archive/`, an ADR without a title, and index errors. The skill reports the findings with the fix it would apply, waits for the user's confirmation, applies only the confirmed fixes, regenerates the index, and runs the diagnosis again. It never commits.
