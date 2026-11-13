---
status: approved
---

# Spec: 001-letters

## Outcome
`alpha.txt`, `beta.txt`, and `gamma.txt` exist at the repository root, each containing its own name.

## Phases

### Phase 1: letters
Done: the three letter files exist at the repository root, each with its own name as the single line.
Files: alpha.txt, beta.txt, gamma.txt
Accept: `test "$(cat alpha.txt)" = alpha && test "$(cat beta.txt)" = beta && test "$(cat gamma.txt)" = gamma` exits 0.

## Constraints
No other product file changes. `scripts/` is not edited.

## Out of scope
Any change to `scripts/`.

## File rules
Auxiliary outputs go under `assets/`, never loose at the track root.
