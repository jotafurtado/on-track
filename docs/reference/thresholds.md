---
title: Thresholds
description: When an assessment is warranted and when it is not, and when a decision becomes an ADR and when it does not.
---

# Thresholds

This page answers two questions the agent settles on its own: when to run an auxiliary assessment, and when to file a decision as an ADR (Architecture Decision Record). Both thresholds are deliberately high, so that the record stays proportional to the request. They are the same in every lane and are not lowered by Off Road.

## Assessment threshold

During the intent, the agent runs `ot-assess` as an auxiliary step only when scope or design depends on a condition of the existing system that reading the relevant files does not settle. That happens when settling it needs at least one of:

- commands run;
- behavior measured;
- evidence weighed across several subsystems;
- or when the conclusion faces material counterevidence.

The agent says in one sentence that it is running the assessment, does not ask permission, and cites the assessment slug in the intent `assessments:` list, never in `research:`.

### What does not warrant an assessment

| Situation | Where it goes instead |
|---|---|
| A fact obtained by reading files | `Verified by the agent` in the intent, with the path that showed it |
| A fact obtained by running one command | `Verified by the agent` in the intent, with the command |
| A premise adopted without checking | `Unverified assumptions` in the intent; verified before a task depends on it |

A user can always ask for an assessment directly. An assessment-only request goes to `ot-assess` without a track; see [Request classes](request-classes.md).

### Research trigger, for contrast

Research has a different trigger. The agent runs `ot-research` when a scope, design, or acceptance decision in the intent depends on an external fact (version behavior, API contract, configuration, limit, license, or price) that is not verified in the repository or in sources already read in the session. Familiarity with a technology does not waive the trigger when the decision depends on such a fact.

## ADR threshold

The ADR threshold applies in every lane: Express, Highway, and Off Road. A decision qualifies only when both conditions hold:

1. **It was a real choice.** At least one alternative was weighed and rejected for a stated reason.
2. **Getting it wrong is expensive.** Reversing it takes more than reverting a diff (a data migration, a coordinated change in consumers, an external commitment), or a future reader would likely undo it without the recorded reason.

### What does not qualify

- Durability alone.
- A restated user preference or instruction.
- A local, easily reversible, or obvious choice.

A user preference with no weighed alternative is a constraint in the intent, not an ADR.

### Where an ADR comes from

| Stage | Trigger | What the agent does |
|---|---|---|
| Intent | The user makes a qualifying decision in the conversation | Files the next numbered `on-track/decisions/<NNN-slug>.md` and cites its slug in the intent `decisions:` list |
| Spec | The user makes a qualifying decision | Files the ADR without a separate request, citing supporting refs, research, assessments, source URLs, or repository paths when available |
| Implement | The user makes a qualifying decision | Files the ADR; if it conflicts with or materially changes the approved spec or tasks, both return to `draft` and need renewed approval (see [Cycle](cycle.md#implementation-limits)) |
| Express | A qualifying decision comes up | Files only that ADR and regenerates the index; the ADR path goes in the crumb's `files` |

An ADR starts as `accepted`. Replacing one files the replacement as the next numbered `accepted` ADR and marks the original `superseded` with `superseded_by`, leaving the original text unchanged. The ADR template is in [Artifacts](artifacts.md#decision-adr).
