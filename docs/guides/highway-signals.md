---
title: Highway signals
description: What to answer at each stop of the Highway and what each answer does.
---

# Highway signals

This page answers what to reply at each of the three stops of the Highway, what green, yellow, and red do at each one, how a stopped track resumes, and how spec approval works.

## The three stops

On the Highway, the intent, spec, and implement stages each end the same way: a four-bullet summary, a next-step line, and a stop. The agent then waits for your signal, read as plain text.

| Stop | Four bullets | Next-step line |
|---|---|---|
| After intent | Problem, proposed outcome, scope, constraints | `. para continuar com a spec` |
| After spec | Outcome, phases, task count, parallel groups | `. para implementar` |
| After implement | Completed tasks, acceptance, review outcome, gate result | `. para ship (marca a track como concluida)` |

The next-step lines are Portuguese in the package. They read as "`.` to continue with the spec", "`.` to implement", and "`.` to ship (marks the track as done)".

The signal is text. The agent keeps the host's question tool for questions and never turns a stop into a dialog.

## The three signals

| Signal | You type | Meaning |
|---|---|---|
| Green | `.`, or a message that only means proceed, in your language (`go`, `yes`, `continue`, `sim`, `verde`) | Go on to the next stage of the same track. |
| Yellow | Any other message, an ambiguous one included | An instruction to the current stage. |
| Red | `x`, or a message that only means stop (`stop`, `red`, `pare`, `vermelho`) | Stop here. |

Green and red are read by meaning, not from a closed word list. A message that mixes a yes with a change, such as "yes, but rename phase 2", is yellow: the stage revises and does not advance.

## What each signal does at each stop

| Stop | Green | Yellow | Red |
|---|---|---|---|
| After intent | Runs the spec stage for the same track. Intent `status` stays `draft`. | Revises the intent, regenerates the index, shows the summary again. | Stops. Changes no `status`, deletes nothing. |
| After spec | Sets `status: approved` in `spec.md` and `tasks.md`, then runs implement. | Revises spec or tasks, regenerates the index, reruns the structure gate, shows the summary again. | Stops. `spec.md` and `tasks.md` stay `draft`, nothing is deleted. |
| After implement | Sets intent `status: shipped` and regenerates the index. | Fixes or revises as instructed, then shows the summary again. | Stops. Intent `status` is unchanged and the implemented code stays. |

Green never changes the intent `status` before ship. The intent stays `draft` from its creation until the implement stage sets `shipped`; approving the intent is not a step and is not required before the spec.

At the implement stop, the ship line appears only when every acceptance row is `met` and no `[blocking]` review finding remains. If a row is `pending`, the agent reports it and keeps fixing or asks how to proceed. Use a yellow reply at this stop to ask for a fix to an open review finding; there is no separate stop for it.

## Red and resuming

Red stops without side effects: no `status` changes, no file is deleted, and no code is undone. It does not mark the track `dropped`. The track stays valid in `draft` and appears in the index with its current phase.

To resume, ask for the same stage again on the same track, for example:

```text
Continue the spec for 001-lp-v2.
```

After a red at the implement stop, ship stays available: ask for it and the agent presents the summary again.

Abandoning a track is a different, explicit decision. When you say you are abandoning it, the agent sets intent `status: dropped`. When you replace it with another track and name that track, the agent sets `status: superseded` with `superseded_by`; it never invents the replacement. See [Cycle](../reference/cycle.md).

## How approval works

Approval happens at one place: green after the spec summary.

- The agent sets `status: approved` in both `spec.md` and `tasks.md` as an approval-only action, completed before any product edit. It may update both files together, but it never mixes approval with product edits.
- Your green covers exactly the `spec.md` and `tasks.md` content that was presented.
- Implementation requires both files approved. Without that, the implement skill refuses to start.

## A material change after approval

After approval, a material change to either file returns both `spec.md` and `tasks.md` to `status: draft`, and implementation needs a new spec summary and a new green before it continues. Material means a change to scope, `Files`, `Accept` criteria, tasks, or group dependencies.

These do not count as material changes: checking task boxes, and the administrative writes the implement stage makes (files under the track's `assets/`, the index, new ADRs).

A material change to approved planning requires renewed approval. When you make a qualifying ADR decision during implementation, the agent files the ADR. If it conflicts with or materially changes the approved spec or tasks, the agent stops, returns both files to `draft`, reconciles the ADR and both planning artifacts, and presents a new spec summary ending with `. para implementar`. If it does not materially change approved scope or design, the agent records the ADR and continues.
