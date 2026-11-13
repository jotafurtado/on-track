---
status: approved
---

# Tasks: 001-letters

## Group A

- [x] Task 1 (Phase 1): create the alpha file. Files: alpha.txt. Validate: `sh scripts/validate-alpha.sh` exits 0.

## Group B (depends: A)

- [ ] Task 2 (Phase 1): create the beta file. Files: beta.txt. Validate: `test "$(cat beta.txt)" = beta` exits 0.

## Group C (depends: B)

- [ ] Task 3 (Phase 1): create the gamma file. Files: gamma.txt. Validate: `test "$(cat gamma.txt)" = gamma` exits 0.
