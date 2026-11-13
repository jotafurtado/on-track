# On Track Method

[Português (Brasil)](README.pt-BR.md)

On Track Method is a lightweight software development life cycle (SDLC) that keeps coding agents on track: you set the direction and answer the signals, and the agent documents, plans, implements, and validates. The record is proportional to the request, so work that does not need a track does not get one.

## Why

Without an explicit process, a request becomes code before anyone settles what has to change. Decisions get lost in the chat. The next session has to rebuild the context from scratch.

On Track Method classifies each request before touching anything, writes down the problem, the outcome, and the limits when the change deserves it, and only implements a full change after you approve its spec and tasks. The artifacts live in your repository as plain Markdown, not only in the conversation.

## How a request travels

![Diagram titled "Three Ways a Request Travels". Express, used when five criteria hold, runs Implement, Check, Crumb, and Report with no track and no signal. Highway, the default, runs Intent and Spec with blocking questions, then Implement with gate and review, then Ship, which you confirm, with a signal after each stage. Off Road, on request, runs Intent and Spec with the agent's own choices added to the questions, then joins the Highway when the spec is approved. Footer: a signal of . proceeds, x stops, any other reply revises the stage; Express leaves a local crumb until the commit; no automatic commit, push, or deploy.](docs/images/en/lanes.png)

- **Express**: a small, reversible edit that meets five criteria, such as at most three files and one check that verifies it. The agent implements it, runs the check, leaves a local note called a crumb for your commit, and reports, with no track and no stop.
- **Highway**: every other edit, and the default. The agent writes an intent, then a spec and tasks, then implements and offers ship, stopping for your signal after each stage.
- **Off Road**: the consulted way onto the Highway, when you want to make more of the decisions yourself. The intent and spec questions also carry the choices the agent would otherwise settle alone, until the spec is approved.

Your explicit choice of lane always wins. The criteria are in the [request classes reference](docs/reference/request-classes.md); see also the [Express changes](docs/guides/express-changes.md) and [Off Road](docs/guides/off-road.md) guides.

## The Highway

![Numbered workflow titled "You Decide. The AI Implements.", drawn as an open arc from request to delivery. 1, you: Start, state the request with /ot-intent. 2, AI agent: Document the intent and limits in intent.md. 3, you: Review, check the intent. 4, AI agent: Plan the specification and tasks in spec.md and tasks.md with /ot-spec. 5, you: Approve, authorize the implementation. 6, AI agent: Implement with code, validation, and review, with /ot-implement. 7, you: Finish, check and confirm, and the change is shipped. A badge says to run /ot-init before you start. Footer: type . to proceed or write another instruction; review the artifacts before you continue; no automatic commit, push, or deploy.](docs/images/en/workflow.png)

The images use the [Claude Code](https://code.claude.com/docs/en/skills) call: `/ot-intent`. In [Codex](https://developers.openai.com/codex/skills), use `$ot-intent` or the `/skills` picker. In other harnesses, you can also ask `Use the ot-intent skill to <goal>`.

At the end of each Highway stage the agent shows a four-bullet summary and the artifacts it wrote, then waits for your signal as plain text:

- **Green**: `.`, or a message that only means proceed, in your language, moves the same track to the next stage; after the spec it approves the spec and tasks, and after implementation it confirms ship.
- **Red**: `x`, or a message that only means stop, halts without changing any status, deleting files, or undoing code, and you resume by asking for the same stage.
- **Yellow**: any other reply, an ambiguous one included, is an instruction to the current stage, which revises and shows the summary again.

Ship marks the track as done; it never commits, pushes, or deploys. Read the [Highway signals guide](docs/guides/highway-signals.md) and the [cycle reference](docs/reference/cycle.md) for every rule.

## Context that stays in the project

![Diagram titled "Context That Stays in the Project.": an AI agent in the center reads the index at on-track/INDEX.md and connects to five supporting artifacts. Refs, material you provide, recorded during the flow at refs/<slug>.md, with no command of their own. Assessments, evidence of the current state with limits and recommendations, at assessments/<YYYY-MM-DD>-<slug>.md, through /ot-assess. Research, external facts and sources, at research/<slug>.md, through /ot-research. Handoff, continuity across sessions, agents, and models, at handoffs/<timestamp>-<slug>.md, through /ot-handoff. Decisions, what, why, and consequences, recorded during the flow at decisions/<NNN-slug>.md, with no command of their own. Every path lives under on-track/. Footer: memory lives in the project files, not in the chat or the model.](docs/images/en/support-context.png)

Research, assessments, and handoffs can be requested at any time, without starting a change, and refs and decisions are recorded on their own during the flow when they are warranted. Agents find all of them through the generated index, so the memory lives in the files instead of depending on the model remembering earlier conversations.

| Artifact | What it preserves | Where it lives |
|---|---|---|
| **Ref** | Material you supply, such as a URL, a document, or an external code snippet that grounds the change. | `on-track/refs/<slug>.md` |
| **Research** | External facts, alternatives, and the sources the agent consulted. | `on-track/research/<slug>.md` |
| **Assessment** | Evidence about the current state of what was evaluated, with limitations and recommendations. | `on-track/assessments/<YYYY-MM-DD>-<slug>.md` |
| **Decision (ADR)** | What was decided, why, and what the choice implies. | `on-track/decisions/<NNN-slug>.md` |
| **Handoff** | The context needed to continue in another session, agent, or model. | `on-track/handoffs/<timestamp>-<slug>.md` |

See the [supporting artifacts guide](docs/guides/supporting-artifacts.md) and, for when an assessment or an ADR is warranted, the [thresholds reference](docs/reference/thresholds.md).

## Quick start

You need Node.js 22.20 or later, `npx`, Git, Bash, and a coding agent that supports skills.

From the root of your project, install all seven skills:

```bash
npx skills add jotafurtado/on-track --skill '*'
```

Open your agent in the same project and initialize the method:

```text
/ot-init
```

This creates the `on-track/` folder, the artifact index, and the managed block in `AGENTS.md`. Running it again duplicates nothing.

Then start a change with a concrete request:

```text
/ot-intent Add password recovery by email.
Do not change the social login.
```

Replying `.` at each stop moves the track to the next stage, so you do not need to call each skill yourself. The [installation page](docs/getting-started/installation.md) covers the options and the checkout installer; [Your first track](docs/getting-started/first-track.md) walks one request from intent to ship.

## Commands

| Group | Command | When to use |
|---|---|---|
| **Setup** | `/ot-init` | When adopting the method in a project. Prepares the structure and the index. |
| **Development, in this order** | `/ot-intent` | Starts a Highway change: records the problem, expected outcome, scope, and limits. |
| | `/ot-spec` | After the intent: writes the spec and the tasks for your review and approval. |
| | `/ot-implement` | After the approved plan: implements the tasks, validates the results, and reviews the delivery. |
| **Support, any time** | `/ot-research` | Researches external facts, documentation, or alternatives with traceable sources. |
| | `/ot-assess` | Evaluates what already exists, with evidence, limitations, and recommendations. |
| | `/ot-handoff` | Records the context to continue in another session, agent, or model. |

## Documentation

| Section | Start here |
|---|---|
| Getting started | [Installation](docs/getting-started/installation.md) |
| Guides | [Express changes](docs/guides/express-changes.md) |
| Reference | [Request classes](docs/reference/request-classes.md) |
| Concepts | [Why On Track](docs/concepts/why-on-track.md) |

The full table of contents is on the [documentation home](docs/index.md). The [evals and their results](evals/evals.md) record how the package is validated with Claude Code, Codex, and Kiro.

Coming from `fast-track-ai`? Follow the [migration steps](docs/getting-started/migrating.md).

## License

[MIT](LICENSE).
