---
status: approved
---

# Spec: 001-greeting

## Outcome
`greeting.txt` contains `hello` and passes `scripts/check-greeting.sh`; `farewell.txt` contains `bye`.

## Phases

### Phase 1: greeting
Done: `greeting.txt` exists at the repository root with the single line `hello`.
Files: greeting.txt
Accept: `sh scripts/check-greeting.sh` exits 0.

### Phase 2: farewell
Done: `farewell.txt` exists at the repository root with the single line `bye`.
Files: farewell.txt
Accept: `test "$(cat farewell.txt)" = bye` exits 0.

## Constraints
`scripts/check-greeting.sh` must not be edited.

## Out of scope
Any change to `scripts/`.

## File rules
Auxiliary outputs go under `assets/`, never loose at the track root.
