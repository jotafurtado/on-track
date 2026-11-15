---
title: Off Road
description: When to ask for Off Road, what it changes in the intent and spec rounds, and where it ends.
---

# Off Road

This page answers when to ask for Off Road, what it changes, where it ends, and what stays exactly as on the Highway.

The Highway is the paved road: the request is clear, the terrain is known, and the agent drives with few stops. Off Road is the unpaved road: the terrain is not mapped yet, so you go slower and stop more often to look at the way ahead.

Off Road is not a lane and not a request class. It is the consulted way onto the Highway: the same track, the same stages, the same artifacts, with more of the early decisions brought to you.

## When to ask for it

Most work runs on the Highway or the Express lane. Ask for Off Road when the request leads into terrain you do not know yet, or when you want to make the design choices yourself:

| Request | Route |
|---|---|
| Build a REST API in this Laravel project. | Highway: the stack is known and the request says what to build. |
| Build an API with Rust as the engine. We have never used Rust here. | Off Road: the libraries, structure, and trade-offs are still open. |

Ask for it in plain words, at the start or at any point during the intent or the spec:

```text
/ot-intent Build the billing API with Rust as the engine. Go Off Road, this is new ground for us.
```

```text
Switch to Off Road for the rest of this spec.
```

The agent may also suggest Off Road on the Highway: when your request is too vague to draft, or when blocking questions remain after the third spec round. It only suggests; the route changes when you ask.

## What changes

While Off Road is on:

- Each round also carries the design choices the agent would otherwise settle alone, besides the blocking questions.
- Rounds have no fixed count, in the intent or in the spec. The agent runs as many as the open points need, one theme each, and stops when none is left.
- Before each round, the agent surveys the established options for that theme (libraries, approaches) and presents them with their trade-offs and its recommendation.
- When the terrain needs study beyond the track, the agent suggests a research.

What stays the same in every round: at most four questions, one theme, each naming the decision it unlocks with the recommendation first, and "you decide" to delegate. Settled points are still not asked. See [Questions and delegation](questions-and-delegation.md).

## Where it ends

Off Road is on from the moment you ask for it until that track's spec is approved, that is, until your green after the spec summary. From the approved spec on, the track runs on the Highway.

## What does not change

| Unchanged | How it works |
|---|---|
| Implement | Same procedure as any track: groups, `Validate`, acceptance, gate. |
| Review | Same rule on every track: every `[blocking]` finding and every in-scope `[important]` finding is fixed, every finding is recorded in `assets/review.md`. |
| Artifacts | Same files: `intent.md`, `spec.md`, `tasks.md`, `assets/`, and the same supporting artifacts. |
| Signals | Same three stops with green, yellow, and red. |
| Thresholds | Same criteria for assessments and ADRs. See [Thresholds](../reference/thresholds.md). |

## A reopened spec

If a material change returns an approved spec to `draft`, Off Road does not turn back on by itself. Ask for it again if you want the extra questions for the revised spec.

## A new session

Off Road is not written to any file: no frontmatter field and no artifact records it. In a new session, while the spec is not yet approved, ask for Off Road again if you want it. This also holds when you resume from a handoff that quotes your earlier request: the quote does not turn Off Road on.

## Off Road or research first

Off Road covers unknown terrain for a request you already have. If the idea itself is still forming, start before the intent with a research or a grilling session (see [When the idea is not clear yet](questions-and-delegation.md#when-the-idea-is-not-clear-yet)).
