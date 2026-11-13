---
title: On Track Method
description: A lightweight, agent-driven software development life cycle that keeps records proportional to the size of each request.
---

# On Track Method

This page answers what On Track Method is, who decides what, and which way a request travels through it. The rest of the documentation is linked at the bottom.

On Track Method is a lightweight software development life cycle for coding agents. It runs as a set of skills and a managed block in your repository's `AGENTS.md`, and it keeps its records as plain Markdown files under `on-track/`. The record follows the size of the request: work that does not need a track does not get one.

## Who decides what

| Role | Responsibilities |
|---|---|
| You | Set the direction, answer blocking questions, and give the signal at each stop of the Highway. |
| The agent | Classifies the request, investigates, documents the intent, plans the spec and tasks, implements, validates, reviews, and reports. |

The method never commits, pushes, or deploys on its own. The commit stays with you or with whoever prepares it (see [Committing](guides/committing.md)).

## Three ways a request travels

Before allocating anything, the agent splits a compound request into parts and classifies each part. Operational work (running, building, inspecting, reporting) runs with no artifact at all. A request that only asks for research or only for an assessment produces that artifact and no track. Edits travel one of these ways:

![On Track Method routes requests through Express, Highway, or Off Road. Express implements, checks, records a crumb, and reports without signals. Highway proceeds through intent, spec, implementation, review, and ship with human signals. Off Road adds consultation during intent and spec, then joins Highway after spec approval.](images/en/lanes.png)

`●` marks a stop where the agent waits for your signal: green (`.`), yellow (any instruction), or red (`x`).

- **Express**: a small, reversible edit that meets five criteria. The agent implements it, runs one check, writes a local note called a crumb, and reports. There is no track and no stop. See [Express changes](guides/express-changes.md).
- **Highway**: every other edit, and the default. The agent writes an intent, then a spec and tasks, then implements and offers ship, stopping for your signal after each stage. See [Your first track](getting-started/first-track.md) and [Highway signals](guides/highway-signals.md).
- **Off Road**: not a separate lane. It is the consulted way onto the Highway: on request, the intent and spec rounds of questions also carry the choices the agent would otherwise settle alone. It ends when the spec is approved. See [Off Road](guides/off-road.md).

## Where to go next

| Section | What it holds |
|---|---|
| Getting started | [Installation](getting-started/installation.md), [Your first track](getting-started/first-track.md), [Migrating from the previous name](getting-started/migrating.md) |
| Guides | [Express changes](guides/express-changes.md), [Highway signals](guides/highway-signals.md), [Off Road](guides/off-road.md), [Questions and delegation](guides/questions-and-delegation.md), [Supporting artifacts](guides/supporting-artifacts.md), [Committing](guides/committing.md) |
| Reference | [Request classes](reference/request-classes.md), [Cycle](reference/cycle.md), [Signals](reference/signals.md), [Artifacts](reference/artifacts.md), [Thresholds](reference/thresholds.md), [Commands](reference/commands.md), [Validation](reference/validation.md), [Agent rules](reference/agent-rules.md) |
| Concepts | [Why On Track](concepts/why-on-track.md), [Design choices](concepts/design-choices.md) |
