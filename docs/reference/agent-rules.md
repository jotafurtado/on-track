---
title: Agent rules
description: The rules an agent follows in a repository that uses On Track Method, as installed by the managed block in AGENTS.md.
---

# Agent rules

This page answers what an agent must do in a repository that uses the method. `ot-init` installs these rules as a managed block in the project's `AGENTS.md`. The block is written to stand alone, because an agent reads it before any skill loads; each skill also stands alone without the block. The list below restates the block in numbered form, with links to the pages that detail each rule.

1. Read `on-track/INDEX.md` before looking for a track or supporting artifact. Never scan the whole `on-track/` tree for discovery. See [Artifacts](artifacts.md#index-md).
2. Classify each request before allocating anything. Split a compound request into parts and handle each part in its own lane. See [Request classes](request-classes.md).
3. The user's explicit choice wins in both directions. Naming `ot-intent`, or asking for a track or an intent, selects the Highway for an edit. Asking to do it directly, or without a track, selects the Express lane.
4. An operational request (running, building, installing, inspecting, or reporting without editing a versioned file) is executed directly, with no track or artifact, and is never recorded inside a track, not even as an `assets/` note.
5. An edit takes the Express lane only when all five Express criteria hold. Announce the lane in one sentence, implement, run the check, write a crumb, and report. Create no track or other file under `on-track/` and do not regenerate the index. There is no signal at the end.
6. If an Express criterion stops holding, stop before the edit that breaks it, name the failed criterion, and start the Highway with `ot-intent`.
7. Every other edit, and every edit with an uncertain Express criterion, takes the Highway: intent, spec, implement, ship. It starts as `intent.md` in `on-track/tracks/NNN-slug/`.
8. Route research-only requests to `ot-research` and assessment-only requests to `ot-assess`, without a track.
9. Do not implement on the Highway until `spec.md` and `tasks.md` both have `status: approved`. Intent approval is not required before the spec.
10. On the Highway, intent, spec, and implement end with a four-bullet summary and a next-step line, then stop for the user's signal, read as plain text. Green (`.` or a message that only means proceed) chains the next skill for the same track and never changes intent `status`. Red (`x` or a message that only means stop) stops, changes no `status`, deletes nothing, and undoes no code. Any other message is yellow: an instruction to the current skill, followed by the summary again. Keep the host's question tool for questions, not signals. See [Signals](signals.md).
11. Investigate first, and ask only what the repository or a command cannot answer. On the Highway ask only blocking questions: one round per stage, at most four, each naming the decision it unlocks, with options and your recommendation first. "You decide" delegates; record the delegated decision and list it in the summary for veto.
12. Off Road is on from the moment the user asks for it until that track's spec is approved. While it is on, an intent or spec round also carries the choices you would otherwise settle alone, within the same cap. A spec returned to `draft` after approval does not turn it back on unless the user asks again.
13. File an ADR only when the decision meets the ADR threshold, in every lane. In the Express lane, a qualifying ADR is the sole artifact exception: file only that ADR and regenerate the index. See [Thresholds](thresholds.md).
14. Keep the track root to `intent.md`, `spec.md`, `tasks.md`, and `assets/`. Loose files are forbidden; auxiliary outputs go under `assets/`.
15. The intent stays `draft` until `shipped`, `dropped`, or `superseded`. `dropped` abandons the work without implementation. `superseded` requires `superseded_by`; never invent it. Implement owns `shipped` and asks before writing it.
16. Write supporting artifacts only at their locations: `on-track/refs/<slug>.md`, `on-track/research/<slug>.md`, `on-track/assessments/<YYYY-MM-DD>-<slug>.md`, `on-track/decisions/<NNN-slug>.md`, `on-track/handoffs/<timestamp>-<slug>.md`.
17. Write the crumb after the Express check, pass or fail, at `on-track/crumbs/<YYYY-MM-DD-HHMMSSZ>-<slug>.md` in UTC. When `on-track/crumbs/.gitignore` is missing, create it with the single line `*`. See [Artifacts](artifacts.md#crumb).
18. To undo an Express change, reverse only your own edits, hunk by hunk, so the user's uncommitted work in the same files survives, and delete the crumb.
19. The method never commits on its own. When preparing commits, read the crumbs oldest first, group the diff by each crumb's `files` and `Changes`, write the message from its `Request` and `Cause`, then delete every crumb you consumed and every crumb whose files no longer differ from `HEAD`. See [Committing](../guides/committing.md).
