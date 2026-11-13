---
id: 001-greeting
status: draft
research: []
assessments: []
refs: []
decisions: []
---

# Intent: greeting and farewell files

## Problem
The repository has no greeting or farewell file for its local smoke check.

## Proposed outcome
`greeting.txt` contains `hello` and passes the registry check; `farewell.txt` contains `bye`.

## Users and systems
Maintainers running local checks. The greeting registry check is `scripts/check-greeting.sh`.

## Constraints
`scripts/check-greeting.sh` is owned by another team and must not be edited.

## Out of scope
Any change to `scripts/`.

## Assumed state

### Stated by the user
- `scripts/check-greeting.sh` is the authoritative greeting check.

### Unverified assumptions
- None.

### Access limits
- None.

## Open questions
None.
