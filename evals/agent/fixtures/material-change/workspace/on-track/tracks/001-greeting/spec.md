---
status: approved
---

# Spec: 001-greeting

## Outcome
`greeting.txt` at the repository root contains the single line `hello`.

## Phases

### Phase 1: greeting
Done: `greeting.txt` exists at the repository root with the single line `hello`.
Files: greeting.txt
Accept: `test "$(cat greeting.txt)" = hello` exits 0.

## Constraints
No other product file changes.

## Out of scope
Any other file, script, or tooling.

## File rules
Auxiliary outputs go under `assets/`, never loose at the track root.
