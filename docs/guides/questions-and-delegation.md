---
title: Questions and delegation
description: When the agent asks on the Highway, how a round of questions works, and how to delegate a decision with "you decide".
---

# Questions and delegation

This page answers when the agent asks you something on the Highway, how a round of questions is shaped, how the intent and spec stages differ, and what happens when you answer "you decide".

## Investigate first

The agent investigates before it asks. It never asks what the repository or a command can answer: it reads the files, runs the inspection it needs, and records what it found. In the intent, a fact it confirmed goes under `Assumed state` > `Verified by the agent`, with the path or command that showed it.

## Blocking questions

On the Highway the agent asks only blocking questions. A question is blocking when its answer changes one of:

- scope,
- security,
- persistence,
- external integration,
- architecture,
- acceptance.

Every other choice the agent settles itself, or records as an open question in the intent, or turns into a task in the spec. To be asked about those choices too, use [Off Road](off-road.md).

## The round

A round holds at most four questions, asked through the host's question tool when it exists. Each question:

- names the decision it unlocks,
- offers options,
- puts the agent's recommendation first.

```text
Signup storage (unlocks: persistence of form submissions)
  1. Send to the existing newsletter provider (recommended)
  2. Store in a new database table
  3. Email the team inbox
```

Signals are not questions. The stop at the end of each stage is read as plain text, never through the question tool (see [Highway signals](highway-signals.md)).

## Intent: one round

The intent stage has one round. The agent asks every blocking question in it, up to four, and writes each answer into the intent body.

- A blocking question beyond the cap goes under `Open questions`, for the spec stage to resolve.
- Any other question the agent settles itself or leaves under `Open questions`.
- Each entry under `Open questions` is a real question: it ends with a question mark and names the decision it unlocks, with an owner when one exists.

## Spec: as many rounds as needed

The spec stage reads the intent's `Open questions` and classifies each one:

| Kind | What happens |
|---|---|
| Blocking | Resolved before the summary, in as many rounds of at most four as needed. The summary and `. para implementar` are withheld while any blocking question remains unanswered. |
| Deferrable | Its answer does not block the overall architecture or scope. It becomes a bounded task whose `Validate` names the expected answer or artifact, in a group that the dependent groups list in `(depends: ...)`. |

Without delegation, the agent invents no answer to either kind.

## "You decide"

You may answer any question with "you decide". That is a delegation: the agent decides, records the decision, and shows it to you for veto.

| Stage | Where the delegated decision is recorded |
|---|---|
| Intent | `intent.md`, under `Constraints` > `Proposed by the agent`, marked `(delegated)` |
| Spec | `spec.md`, under `Constraints`, marked `(delegated)` |

```markdown
### Proposed by the agent
- Signup submissions go to the existing newsletter provider. (delegated)
```

## Vetoing a delegated decision

Delegated decisions appear in the stage summary, before the track location and the next-step line. To veto one, reply with the change you want instead of `.`: any such reply is a yellow signal, so the agent revises the intent or spec and shows the summary again. In the intent summary, the other constraints the agent proposed on its own are listed the same way, for the same veto. An agent-proposed constraint is allowed only when omitting it risks data loss, a security problem, or breaking the stated outcome. It must name that risk and must not widen the outcome. Delegated decisions, marked `(delegated)`, are the other permitted entries.
