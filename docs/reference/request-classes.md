---
title: Request classes
description: The five classes a request can fall into, what each one records, the Express criteria, and how compound requests, explicit choice, and escalation work.
---

# Request classes

This page answers how the agent decides what a request becomes. Every request is classified before the agent allocates a track number, a track, or any artifact. The class decides the lane the work travels and what, if anything, it leaves under `on-track/`.

## The five classes

| Class | What it is | What it records |
|---|---|---|
| Operational | Running, building, installing, inspecting, or reporting without editing a versioned file of the target repository | Nothing. No track, no artifact, and never a note inside a track, including under `assets/` |
| Express | An edit for which all five Express criteria hold | One local crumb until the commit. No track, no other file under `on-track/`, no index regeneration |
| Highway | Every other edit, and any edit where an Express criterion is uncertain. This is the default | The full cycle: `intent.md`, `spec.md`, `tasks.md`, and `assets/` in `on-track/tracks/NNN-slug/` |
| Research only | Investigating an external fact, with no desired state change in the system | `on-track/research/<slug>.md` and the index, through `ot-research`. No track |
| Assessment only | Evaluating or auditing what exists, with no desired state change in the system | `on-track/assessments/<YYYY-MM-DD>-<slug>.md` and the index, through `ot-assess`. No track |

Off Road is not a class and not a third lane. It is the consulted way onto the Highway: the same cycle, with more questions to the user during intent and spec. See [Off Road](../guides/off-road.md).

A request that only asks for a handoff goes to `ot-handoff`, which writes the handoff and regenerates the index without a track. See [Commands](commands.md).

## Express criteria

A request takes the Express lane only when all five criteria hold:

1. The request states what to build, with no open question that would change it.
2. At most three files change.
3. None of these changes: a public contract (API, CLI flags, schema, a file format someone else consumes), persisted data or a migration, a security control (authentication, authorization, secrets, permissions), or a dependency (added, upgraded, or removed).
4. Reverting the diff alone undoes the change, with no data backfill and no external side effect.
5. One existing command or one observable check verifies it.

If any criterion is uncertain, the request takes the Highway.

## What the Express lane does

1. The agent says in one sentence that the change takes the Express lane.
2. It implements the change.
3. It runs the check.
4. It writes a crumb, whether the check passed or failed.
5. It reports the change and the result.

The report ends the work. There is no signal and no stop at the end of the Express lane. Apart from the crumb, the agent creates no track and no file under `on-track/` and does not regenerate the index. The only artifact exception is a decision that meets the ADR threshold: the agent files only that ADR and regenerates the index. See [Thresholds](thresholds.md).

The crumb shape is in [Artifacts](artifacts.md#crumb). How to undo an Express change and how crumbs feed a commit are in [Express changes](../guides/express-changes.md) and [Committing](../guides/committing.md).

## Compound requests

A request that asks for several things is split into parts before anything is allocated. Each part is classified on its own and handled in its own lane. One message can produce an operational action, an Express change, and a Highway track at the same time.

When a request reaches `ot-intent` without the user naming the skill, its operational and Express parts create no track. The skill stops after those parts unless Highway parts remain.

When a request is too vague or ambiguous to classify, the agent asks in one round of at most four questions, through the host's question tool when it exists.

## Explicit choice

The user's explicit choice wins in both directions:

| The user | Effect |
|---|---|
| Names `ot-intent`, or asks for a track or an intent | The edit takes the Highway, even if it would qualify for Express |
| Asks to do it directly, or without a track | The edit takes the Express lane |
| Asks for Off Road | The Highway track runs with Off Road consultation from that moment until its spec is approved |

## Escalation from Express to Highway

If an Express criterion stops holding while the agent works, the agent stops before the edit that would break it, names the criterion that failed, and starts the Highway with `ot-intent`.

## Routing inside `ot-intent`

If a request that reaches `ot-intent` is purely investigative ("research", "investigate") or evaluative ("assess", "audit") and does not describe a desired state change, the skill routes it to `ot-research` or `ot-assess` as a direct call. It creates no track directory and no `intent.md`.
