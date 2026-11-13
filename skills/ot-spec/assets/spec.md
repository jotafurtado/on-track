---
status: draft
---

# Spec: NNN-slug

Thin product description owned by this package.

## Outcome
What is true when the track closes.

## Phases

Each phase separates the delivered state from its check. `Done:` names the delivered, observable state an observer can see when the phase closes. `Accept:` names the check that proves that state: a command with its expected result, or an observable procedure with its expected observation.

### Phase 1: name
Done: the delivered, observable state when this phase closes.
Files: explicit list of touched files.
Accept: the command with its expected result, or the observable procedure with its expected observation.

### Phase 2: name
Done:
Files:
Accept:

## Constraints
Limits that bind the work.

## Out of scope
Repeat the intent limit, never widen it.

## File rules
Auxiliary outputs (inventories, reports, exports, evidence) go under `assets/`, never loose at the track root. Track root holds only `intent.md`, `spec.md`, `tasks.md`, and `assets/`.
