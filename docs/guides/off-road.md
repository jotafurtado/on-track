---
title: Off Road
description: When to ask for Off Road, what it changes in the intent and spec rounds, and where it ends.
---

# Off Road

This page answers when to ask for Off Road, what it changes, where it ends, and what stays exactly as on the Highway.

Off Road is not a lane and not a request class. It is the consulted way onto the Highway: the same track, the same stages, the same artifacts, with more of the early decisions brought to you.

## When to ask for it

On the Highway the agent asks only blocking questions; other questions may be settled during intent or left under `Open questions`, and deferrable questions become bounded tasks during spec (see [Questions and delegation](questions-and-delegation.md)). Ask for Off Road when the request still depends on decisions you want to make yourself: a layout you have opinions about, naming, the order of the work, which of two reasonable approaches to take.

Ask for it in plain words, at the start or at any point during the intent or the spec:

```text
/ot-intent Redesign the pricing page. Go Off Road, I want to weigh in on the choices.
```

```text
Switch to Off Road for the rest of this spec.
```

## What changes

While Off Road is on, each intent and spec round of questions also carries the choices the agent would otherwise settle alone. Nothing else about the round changes:

- At most four questions per round.
- Each question names the decision it unlocks and offers options, with the agent's recommendation first.
- You may answer any question with "you decide"; the agent records the delegated decision and lists it in the summary for veto.
- The intent stage still has one round; the spec stage still uses as many rounds as needed to resolve its blocking questions.

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
