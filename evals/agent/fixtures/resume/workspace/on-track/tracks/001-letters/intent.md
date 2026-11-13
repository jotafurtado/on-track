---
id: 001-letters
status: draft
research: []
assessments: []
refs: []
decisions: []
---

# Intent: letter files

## Problem
The local smoke check expects three letter files that do not all exist yet.

## Proposed outcome
`alpha.txt`, `beta.txt`, and `gamma.txt` exist at the repository root, each containing its own name.

## Users and systems
Maintainers running local checks. No external system is touched.

## Constraints
No other product file changes. `scripts/` is not edited.

## Out of scope
Any change to `scripts/`.

## Assumed state

### Stated by the user
- `alpha.txt` was already delivered and validated in an earlier session.

### Unverified assumptions
- None.

### Access limits
- None.

## Open questions
None.
