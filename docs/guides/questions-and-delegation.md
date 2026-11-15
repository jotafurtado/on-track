---
title: Questions and delegation
description: What the agent asks you, how a round of questions works on the Highway and Off Road, and how to delegate a decision with "you decide".
---

# Questions and delegation

This page answers what the agent asks you during intent and spec, how a round of questions is shaped, how many rounds each route gets, and what happens when you answer "you decide".

## What is never asked

The agent asks only what is still open. Before asking, it checks whether the point is already settled by one of these sources:

- your request,
- the context it already holds: `AGENTS.md` and the files it read this session,
- a lookup tool your project names for this, such as a code graph or a memory server,
- one targeted read: a manifest, `.env.example`, `on-track/decisions/`.

If your `AGENTS.md` already says where the system is hosted, you will not be asked where it will be hosted. The settled fact goes into the artifact with its source: in the intent, under `Assumed state` > `Verified by the agent`.

To spare yourself questions, write the stable facts of your project (stack, hosting, conventions) in `AGENTS.md` or in a document it points to.

## Blocking questions

A question is blocking when its answer changes one of:

- scope,
- security,
- persistence,
- external integration,
- architecture,
- acceptance.

Blocking questions are asked on the Highway and in [Off Road](off-road.md) alike. The routes differ only in what else they ask.

## Questions serve your request

Each question clarifies what you asked, or proposes a way to reach it. The agent does not open new fronts you did not ask about.

A decision already recorded, in an ADR or a documented choice, stays as written. A choice that is only in use, with no recorded reason, may receive a suggestion when a clearly better option serves your request, such as a more established library that fits the project. A suggestion takes one of the round's slots and comes with the agent's recommendation.

## The round

A round holds at most four questions, asked through the host's question tool when it exists, all on one theme: data model in one round, libraries in the next, infrastructure after that. Each question:

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

## How many rounds

| Route | Intent | Spec |
|---|---|---|
| Highway | One round, blocking questions only | Up to three rounds, blocking questions only |
| Off Road | As many rounds as needed, blocking questions plus design choices | As many rounds as needed, blocking questions plus design choices |

On the Highway:

- In the intent, a blocking question beyond the cap goes under `Open questions`, for the spec to resolve. Any other question the agent settles itself or leaves there.
- In the spec, if blocking questions remain after the third round, the agent stops, lists them, and suggests Off Road. The summary and `. para implementar` stay withheld until each one is answered or delegated.
- If your request is too vague to draft and the sources above do not settle it, the agent suggests Off Road and keeps going on the Highway unless you take the suggestion.

## Open questions in the spec

The spec reads the intent's `Open questions` and classifies each one:

| Kind | What happens |
|---|---|
| Blocking | Resolved before the summary, within the round limits above. |
| Deferrable | Its answer does not block the overall architecture or scope. It becomes a bounded task whose `Validate` names the expected answer or artifact, in a group that the dependent groups list in `(depends: ...)`. |

Each entry under `Open questions` is a real question: it ends with a question mark and names the decision it unlocks, with an owner when one exists. Without delegation, the agent invents no answer to either kind.

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

Delegated decisions appear in the stage summary, before the track location and the next-step line. To veto one, reply with the change you want instead of `.`: any such reply is a yellow signal, so the agent revises the intent or spec and shows the summary again. In the intent summary, the other constraints the agent proposed on its own are listed the same way, for the same veto. An agent-proposed constraint is allowed only when omitting it risks data loss, a security problem, or breaking the stated outcome. It must name that risk and must not widen the outcome.

## When the idea is not clear yet

The intent starts when you know what you want to build. If the idea itself is still forming, work it out before the intent:

- Ask for a research (`/ot-research`) on the topic, read it, then open the intent.
- Or run a grilling session first. Matt Pocock's [`grill-me`](https://github.com/mattpocock/skills/tree/main/skills/productivity/grill-me) skill is one option; it is not part of this package.

If the agent notices that answering your request would mean exploring alternatives to the request itself, it says so and suggests a research.
