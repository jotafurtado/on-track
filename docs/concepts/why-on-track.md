---
title: Why On Track
description: The problem On Track Method addresses, proportional record keeping, the split between human decisions and agent execution, and the metaphor behind the names.
---

# Why On Track

This page answers why the method exists and why it is shaped the way it is. The rules themselves are in the [Reference](../reference/request-classes.md) pages.

## The problem

A coding agent working on a real repository tends to fail in one of two directions.

It interrogates. It asks about things the repository or a command could answer, asks about choices that do not change the outcome, and turns a small change into a meeting.

Or it guesses. It settles scope, security, persistence, or acceptance on its own, and the user finds out after the code is written.

The records around that work fail the same way. Either nothing is written down, and the next session, agent, or person cannot tell why the code is the way it is, or every change produces the same pile of documents, and the pile stops being read.

## Proportional record keeping

On Track Method makes the record follow the size of the request. What does not need a track does not get one.

| Request | Record |
|---|---|
| Run, build, inspect, report | None |
| A small, bounded, reversible edit (Express) | One local crumb, consumed at commit time |
| Any other edit (Highway) | A track: intent, spec, tasks, and evidence under `assets/` |
| A question about the outside world | A research file |
| An assessment-only request, or a change whose scope or design meets the assessment threshold | An assessment file |

The supporting records follow the same idea. An auxiliary assessment is written when a change meets the assessment threshold; a direct assessment request needs no track. An ADR is written only for a real choice that is expensive to get wrong. `ot-handoff` captures context when switching harness or model, ending a session, or responding to a handoff request. The thresholds are in [Thresholds](../reference/thresholds.md).

## The human decides, the agent executes

The human sets the direction and answers the signals. The agent documents, plans, implements, and validates between them.

That split shows up in three places:

- **Questions.** The agent investigates first and asks only blocking questions, those whose answer changes scope, security, persistence, external integration, architecture, or acceptance, with its recommendation first. The user can delegate any question with "you decide", and every delegated decision comes back in the summary for veto. When the user wants a bigger say, Off Road also brings the agent's own choices to the user, until the spec is approved.
- **Signals.** Each Highway stage ends at a stop where the user answers in plain text: proceed, adjust, or stop. Nothing is approved by silence or by a passing check. See [Signals](../reference/signals.md).
- **Commits.** The method never commits. The commit belongs to the maintainer.

The agent classifies the request, writes the artifacts, runs the checks, and records the evidence. The review fixes every `[blocking]` finding and each `[important]` finding whose fix stays within the spec `Files:`; other findings remain open.

## The metaphor

The name says what the method is for: keeping agent work on track, with the human holding the direction.

The vocabulary follows a road:

- **Express** is the short lane for a change that needs no stops.
- **Highway** is the main road every other change takes, with three stops on the way to ship.
- **Off Road** is the consulted way onto the Highway, for a request that depends on more of the user's decisions. It rejoins the Highway once the spec is approved.
- **Signals** are green, yellow, and red, like traffic lights.
- **Crumbs** are the trail an Express change leaves behind so the commit can find its way back.

The reasons behind each of these choices are in [Design choices](design-choices.md).
