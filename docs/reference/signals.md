---
title: Signals
description: "Green, yellow, and red at each Highway stop: the tokens, the messages that count, and the effect on status and files."
---

# Signals

This page answers what each reply does at each stop of the Highway. The intent, spec, and implement stages each end with a four-bullet summary and a next-step line, then stop for the user's signal. The signal is plain text. The host's question tool is kept for questions, not for signals.

## Reading a reply

| Signal | Canonical token | Also counts | Meaning |
|---|---|---|---|
| Green | `.` | A message that only means proceed, in the user's language, such as `go`, `yes`, `continue`, `sim`, `verde` | Proceed: chain the next skill for the same track without asking for a command |
| Red | `x` | A message that only means stop, such as `stop`, `red`, `pare`, `vermelho` | Stop |
| Yellow | None | Any other message, an ambiguous one included | Treat it as an instruction to the current skill, then present the summary again |

The words listed are examples, not a closed list: what counts is the meaning of the message. A message that mixes approval with a change, such as "yes, but rename phase 2", is yellow.

## After the intent

Next-step line: `. para continuar com a spec`.

| Signal | Effect on status | Effect on files | What happens next |
|---|---|---|---|
| Green | None. The intent stays `draft` | None | `ot-spec` starts for the same track |
| Red | None | Nothing is deleted | The agent stops. The track stays valid in `draft` and resumes when the user asks for the intent stage again |
| Yellow | None | `intent.md` is revised as instructed and the index is regenerated | The agent reports any index validation error, otherwise presents the intent summary again |

## After the spec

Next-step line: `. para implementar`.

| Signal | Effect on status | Effect on files | What happens next |
|---|---|---|---|
| Green | `spec.md` and `tasks.md` become `status: approved`. Intent status does not change | Only the approval write, completed before any product edit | `ot-implement` starts for the same track |
| Red | None. `spec.md` and `tasks.md` stay `draft` | Nothing is deleted | The agent stops. The track resumes when the user asks for the spec stage again |
| Yellow | None | `spec.md` or `tasks.md` revised as instructed, index regenerated, structure gate rerun | The agent presents the spec summary again |

Approval covers exactly the version that was presented. A later material change returns both files to `draft`; see [Cycle](cycle.md#approval-and-material-changes).

## After implement

Next-step line: `. para ship (marca a track como concluida)`. It appears only when every acceptance row is `met` and no `[blocking]` review finding remains.

| Signal | Effect on status | Effect on files | What happens next |
|---|---|---|---|
| Green | Intent becomes `status: shipped` | Index regenerated | The track is done |
| Red | None. Intent `status` stays as it is | Implemented code is kept. Nothing is undone | The agent stops. Ship stays available when the user asks for it again |
| Yellow | None | The agent fixes or revises as instructed before shipping | The agent presents the implement summary again |

To have an open review finding fixed, answer yellow at this stop. There is no other stop in the cycle for it.

## What red never does

Red stops without changing any `status`, deletes nothing, and undoes no code. It never marks a track `dropped`; dropping a track is a separate decision the maintainer declares. See [Cycle](cycle.md#abandoning-or-replacing-a-track).

## Lanes without signals

The Express lane has no signal: the report ends the work. Operational requests, research-only, and assessment-only requests have no signal either; a direct `ot-research` or `ot-assess` call reports its result, path, and index outcome without a `.` line.
