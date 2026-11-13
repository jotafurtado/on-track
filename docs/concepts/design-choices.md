---
title: Design choices
description: The choices behind On Track Method and what was weighed against each one.
---

# Design choices

This page answers why the method made some choices that may look surprising, and what each choice was weighed against. The rules themselves are in the Reference pages linked from each section.

## Signals are plain text

At each Highway stop, the user answers in plain text: `.` for green, `x` for red, anything else for yellow. Outside the two tokens, the meaning of the message counts, in any language, not a closed list of words.

Weighed against: answering through the host's question tool, as a dialog with buttons. A dialog can cover the summary the user needs to read to decide, and typing `.` is faster than any click. The question tool stays reserved for actual questions.

The tokens are symbols because symbols have no language. The next-step lines that announce them (`. para continuar com a spec`, `. para implementar`, `. para ship (marca a track como concluida)`) are kept as the package writes them.

See [Signals](../reference/signals.md).

## No stop at the end of Express

The Express lane announces itself, implements, checks, writes a crumb, and reports. The report ends the work; there is no signal.

Weighed against: a closing signal like the Highway's. On an Express change, that stop would only announce that the change can be undone, and the user can already ask for that at any moment. Undoing is an ordinary request that also deletes the crumb.

See [Express changes](../guides/express-changes.md).

## The method never commits

No skill and no lane commits. The commit belongs to the maintainer, or to whatever tool the maintainer uses to prepare it.

Weighed against: committing at the end of each change. The method instead leaves what a commit needs: on the Highway, the intent, spec, and tasks explain the change; in the Express lane, the crumb records the request, the cause, the files, and the verification.

See [Committing](../guides/committing.md).

## Off Road is an on-ramp, not a lane

Off Road is the consulted way onto the Highway. It changes only one thing: while it is on, an intent or spec round also carries the choices the agent would otherwise settle alone, within the same cap of four questions. It ends when the spec is approved.

Weighed against: a third lane with its own flow. Off Road has no artifacts, signals, or thresholds of its own; it uses the Highway's. That is why it can be turned on in the middle of an intent or a spec, and why implement and review are the same for every track. A spec returned to `draft` does not turn it back on unless the user asks again, and no file records it, so a new session needs the request again while the spec is unapproved.

See [Off Road](../guides/off-road.md).

## One review rule

The implement review fixes every `[blocking]` finding and every `[important]` finding whose fix stays within the spec files, and leaves the rest open. The rule is the same in every track. Every finding is recorded with its disposition in `assets/review.md`, and the ship summary names each open `[important]`.

Weighed against: letting the review behave differently depending on how the track was planned, for example after Off Road. A single rule makes the outcome predictable, and the record makes it visible. A user who wants an open finding fixed answers yellow at the ship stop.

See [Validation](../reference/validation.md#implement-review).

## No backward compatibility with the former name

The method was renamed. Its tree, managed block, commands, and scripts changed names, and there is no automatic migration: `ot-init` refuses a project that still has the legacy tree or legacy managed block, changes nothing, and prints the manual steps.

Weighed against: migrating automatically. The refusal writes nothing, and the agent renames or deletes nothing unless the user asks, so moving the user's files stays with the user.

See [Migrating](../getting-started/migrating.md).

## Crumbs stay outside git

A crumb lives in `on-track/crumbs/`, which ignores itself with a `.gitignore` holding `*`. Crumbs stay out of git and the index. During commit preparation, the maintainer or tool deletes consumed crumbs and crumbs whose files no longer differ from `HEAD`.

Weighed against: versioning the note, or giving the Express lane a track. A crumb has no id, no status, and no number, so it uses no track numbering. The managed block defines the crumb fields and body sections so Express needs no dedicated skill. `ot-intent` carries the same Express procedure when it classifies a request into that lane. A new field is added only when commit preparation has a defined reader for it.

See [Artifacts](../reference/artifacts.md#crumb).
