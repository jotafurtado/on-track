---
status: approved
---

# Tasks: 001-greeting

## Group A

- [ ] Task 1 (Phase 1): create the greeting file. Files: greeting.txt. Validate: `sh scripts/check-greeting.sh` exits 0.

## Group B (depends: A)

- [ ] Task 2 (Phase 2): create the farewell file. Files: farewell.txt. Validate: `test "$(cat farewell.txt)" = bye` exits 0.
