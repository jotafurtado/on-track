#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
mode="${1:-all}"
work="$(mktemp -d "${TMPDIR:-/tmp}/on-track-skill-standards.XXXXXX")"
trap 'rm -rf "$work"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

pass() {
  echo "PASS: $1"
}

assert_file() {
  [ -f "$1" ] || fail "missing file: $1"
}

assert_not_file() {
  [ ! -e "$1" ] || fail "unexpected file: $1"
}

assert_dir() {
  [ -d "$1" ] || fail "missing directory: $1"
}

assert_contains() {
  grep -Fq "$2" "$1" || fail "$1 does not contain: $2"
}

assert_not_contains() {
  if grep -Fq "$2" "$1"; then
    fail "$1 unexpectedly contains: $2"
  fi
}

assert_not_matches() {
  if grep -Eq "$2" "$1"; then
    fail "$1 unexpectedly matches: $2"
  fi
}

expect_failure() {
  label="$1"
  shift
  if "$@" >"$work/failure.out" 2>"$work/failure.err"; then
    fail "$label unexpectedly succeeded"
  fi
}

frontmatter_field() {
  awk -v key="$2" '/^---$/{section++; next} section == 1 && index($0, key ":") == 1 { sub("^[^:]+:[[:space:]]*", ""); print; exit }' "$1"
}
write_intent() {
  root="$1"
  track="$2"
  status="$3"
  mkdir -p "$root/on-track/tracks/$track"
  cat >"$root/on-track/tracks/$track/intent.md" <<EOF
---
id: $track
status: $status
research: []
decisions: []
---
EOF
}

write_spec() {
  file="$1"
  status="${2:-approved}"
  mkdir -p "$(dirname "$file")"
  cat >"$file" <<EOF
---
status: $status
---

# Spec

### Phase 1: fixture
Done: fixture done
Files: fixture
Accept: fixture accepted
EOF
}

write_plan() {
  file="$1"
  status="$2"
  cat >"$file" <<EOF
---
status: $status
---

# Plan

Files: fixture
Accept: fixture
EOF
}

write_tasks() {
  file="$1"
  status="$2"
  checkbox="$3"
  cat >"$file" <<EOF
---
status: $status
---

# Tasks

## Group A
- [$checkbox] T001 Fixture. Files: fixture. Validate: true
EOF
}

write_handoff() {
  file="$1"
  captured="$2"
  focus="$3"
  mkdir -p "$(dirname "$file")"
  cat >"$file" <<EOF
---
captured: $captured
owner: maintainer
focus: $focus
---

# Handoff: $focus

## Objective
Fixture objective.

## Active user instructions, verbatim
> Preserve this exact instruction.

## Current state
Verified fixture state.

## Completed
- Fixture completed.

## Next actions
1. Run the next fixture.
2. Then the following step.

## Unresolved decisions
- None.

## Relevant paths and durable artifacts
- on-track/INDEX.md

## Observed command results
- Fixture command passed.

## Blockers and risks
- None known.
EOF
}

write_handoff_no_actions() {
  file="$1"
  captured="$2"
  focus="$3"
  mkdir -p "$(dirname "$file")"
  cat >"$file" <<EOF
---
captured: $captured
owner: maintainer
focus: $focus
---

# Handoff: $focus

## Objective
Fixture objective.

## Active user instructions, verbatim
> Preserve this exact instruction.

## Current state
Verified fixture state.

## Completed
- Fixture completed.

## Unresolved decisions
- None.

## Relevant paths and durable artifacts
- on-track/INDEX.md

## Observed command results
- Fixture command passed.

## Blockers and risks
- None known.
EOF
}

init_script="$repo_root/skills/ot-init/scripts/on-track-init.sh"
index_script="$repo_root/skills/ot-init/scripts/on-track-index.sh"
gate="$repo_root/skills/ot-spec/scripts/on-track-gate.sh"

# fake_agent is an executable stand-in for a harness CLI. It answers the
# prerequisite probes, then emits canned native events (FAKE_EVENTS file, or a
# minimal successful session for FAKE_KIND). It never contacts a model.
write_fake_agent() {
  fake_agent="$work/fake-agent"
  if [ -x "$fake_agent" ]; then return 0; fi
  cat >"$fake_agent" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  --version) echo "fake-agent 0.0.0"; exit 0;;
  whoami|login) exit 0;;
  auth) echo '{"loggedIn":true}'; exit 0;;
esac
case "$PWD" in
  */compat/workspace) printf 'ftai-compat-7f3a9c2e\n' >token.txt;;
  */resume/workspace) : >.eval-validate-alpha-ran;;
esac
if [ -n "${FAKE_SETUP:-}" ]; then bash "$FAKE_SETUP"; fi
if [ -n "${FAKE_EVENTS:-}" ]; then cat "$FAKE_EVENTS"; exit 0; fi
case "${FAKE_KIND:-}" in
  claude) printf '%s\n' '{"type":"system","subtype":"init","session_id":"fake-session","model":"fake","permissionMode":"dontAsk","claude_code_version":"0.0.0"}' '{"type":"result","subtype":"success","is_error":false,"session_id":"fake-session","usage":{"input_tokens":1,"output_tokens":1}}';;
  codex) printf '%s\n' '{"type":"thread.started","thread_id":"fake-thread"}' '{"type":"turn.started"}' '{"type":"turn.completed","usage":{"input_tokens":1,"output_tokens":1}}';;
  kiro) printf '%s\n' '{"type":"runStarted","data":{}}' '{"type":"metadata","data":{"sessionId":"fake-session"}}' '{"type":"runFinished","data":{"sessionId":"fake-session","status":"success","stopReason":"end_turn"}}';;
esac
EOF
  chmod +x "$fake_agent"
}

# Unknown harnesses and missing executables must be reported before any CLI starts.
check_agent_runner_prerequisites() {
  tripwire="$work/tripwire"
  printf '#!/usr/bin/env bash\n: >"%s.called"\nexit 0\n' "$tripwire" >"$tripwire"
  chmod +x "$tripwire"
  rm -f "$tripwire.called"
  runner="$repo_root/evals/run-agent-evals.sh"
  for harness_name in kiro claude codex; do
    case "$harness_name" in
      kiro) cli_env=KIRO_CLI; cli_label="Kiro CLI";;
      claude) cli_env=CLAUDE_CLI; cli_label="Claude Code CLI";;
      codex) cli_env=CODEX_CLI; cli_label="Codex CLI";;
    esac
    out_file="$work/agent-prereq-$harness_name.out"
    env KIRO_CLI="$tripwire" CLAUDE_CLI="$tripwire" CODEX_CLI="$tripwire" "$cli_env=$work/missing-$harness_name-cli" \
      bash "$runner" all --harness "$harness_name" >"$out_file" 2>&1 || fail "agent-eval runner without a $cli_label did not exit 0"
    assert_contains "$out_file" "HARNESS: $harness_name"
    assert_contains "$out_file" "RESULT: compat prerequisite-unavailable: $cli_label not found"
    assert_contains "$out_file" "prerequisite-unavailable=10"
    [ "$(grep -c '^RESULT: .* prerequisite-unavailable: ' "$out_file")" -eq 10 ] || fail "$harness_name: not all ten selectors reported prerequisite-unavailable"
    [ ! -e "$tripwire.called" ] || fail "$harness_name: a CLI was invoked despite a missing prerequisite"
  done
  # Default harness is Kiro.
  env KIRO_CLI="$work/missing-default-cli" CLAUDE_CLI="$tripwire" CODEX_CLI="$tripwire" bash "$runner" all >"$work/agent-prereq-default.out" 2>&1 || fail "default agent-eval invocation did not exit 0"
  assert_contains "$work/agent-prereq-default.out" "HARNESS: kiro"
  assert_contains "$work/agent-prereq-default.out" "RESULT: compat prerequisite-unavailable: Kiro CLI not found"
  # Unknown harness and unsupported settings fail with a usage error before any CLI.
  rc=0
  env KIRO_CLI="$tripwire" CLAUDE_CLI="$tripwire" CODEX_CLI="$tripwire" bash "$runner" all --harness bogus >"$work/agent-unknown.out" 2>&1 || rc=$?
  [ "$rc" -eq 2 ] || fail "unknown harness exited $rc, expected 2"
  assert_contains "$work/agent-unknown.out" "unknown harness: bogus"
  rc=0
  env KIRO_CLI="$tripwire" CLAUDE_CLI="$tripwire" CODEX_CLI="$tripwire" bash "$runner" all --harness claude --effort bogus >"$work/agent-effort.out" 2>&1 || rc=$?
  [ "$rc" -eq 2 ] || fail "unsupported effort exited $rc, expected 2"
  assert_contains "$work/agent-effort.out" "not supported by claude"
  [ ! -e "$tripwire.called" ] || fail "a CLI was invoked for a usage error"
}

# With a stand-in CLI per harness, every scenario is staged under the selected
# harness's native directory with the canonical prompts plus only the location hint.
check_agent_runner_staging() {
  write_fake_agent
  codex_home_dir="$work/codex-home"
  mkdir -p "$codex_home_dir"
  source_before="$(cd "$repo_root/skills" && find . -type f -exec shasum -a 256 {} + | LC_ALL=C sort -k2 | shasum -a 256)"
  for harness_name in kiro claude codex; do
    case "$harness_name" in
      kiro) cli_env=KIRO_CLI; native=.kiro;;
      claude) cli_env=CLAUDE_CLI; native=.claude;;
      codex) cli_env=CODEX_CLI; native=.agents;;
    esac
    keep="$work/staging-$harness_name"
    out_file="$work/staging-$harness_name.out"
    env "$cli_env=$fake_agent" FAKE_KIND="$harness_name" CODEX_HOME="$codex_home_dir" \
      bash "$repo_root/evals/run-agent-evals.sh" all --harness "$harness_name" --timeout 60 --keep-dir "$keep" >"$out_file" 2>&1 || true
    assert_contains "$out_file" "HARNESS: $harness_name"
    assert_contains "$out_file" "RESULT: compat pass"
    jq -e --arg h "$harness_name" '.harness == $h' "$keep/$harness_name/compat/result.json" >/dev/null || fail "$harness_name compat result.json does not identify the harness"
    for fixture_dir in "$repo_root"/evals/agent/fixtures/*/; do
      scenario="$(basename "$fixture_dir")"
      for turn_file in "$fixture_dir"turns/turn-*.txt; do
        original="$(cat "$turn_file")"
        case "$original" in
          *.kiro*|*.claude/*|*.agents/*) fail "fixture prompt names a harness location: $turn_file";;
        esac
        staged_file="$keep/$harness_name/$scenario/turns/$(basename "$turn_file")"
        [ -f "$staged_file" ] || fail "$harness_name did not stage $scenario/$(basename "$turn_file")"
        expected="${original/ in this repository./ in this repository. The skill is available under $native/skills/.}"
        [ "$(cat "$staged_file")" = "$expected" ] || fail "$harness_name staged prompt differs from the fixture beyond the location hint: $staged_file"
      done
      if [ "$scenario" != "compat" ]; then
        skill_copy="$keep/$harness_name/$scenario/workspace/$native/skills/ot-spec/SKILL.md"
        [ -f "$skill_copy" ] || fail "$harness_name did not stage the package under $native/skills for $scenario"
        cmp -s "$skill_copy" "$repo_root/skills/ot-spec/SKILL.md" || fail "$harness_name staged skill differs from the package"
        [ ! -L "$keep/$harness_name/$scenario/workspace/$native/skills/ot-spec" ] || fail "$harness_name staged skill is a symlink into the package"
        for other in .kiro .claude .agents; do
          [ "$other" = "$native" ] || [ ! -e "$keep/$harness_name/$scenario/workspace/$other" ] || fail "$harness_name workspace has an unrelated $other directory"
        done
      fi
    done
    cmp "$keep/$harness_name/approval/turns/turn-01.txt" "$keep/$harness_name/red-signal/turns/turn-01.txt" || fail "$harness_name red-signal did not reuse the spec prompt"
    printf 'x\n' >"$work/red-signal-turn.expected"
    cmp "$work/red-signal-turn.expected" "$keep/$harness_name/red-signal/turns/turn-02.txt" || fail "$harness_name red-signal turn 2 is not x"
    cmp "$repo_root/evals/agent/fixtures/approval/workspace/on-track/tracks/001-greeting/intent.md" "$keep/$harness_name/red-signal/workspace/on-track/tracks/001-greeting/intent.md" || fail "$harness_name red-signal did not reuse the intent fixture"
    cmp "$repo_root/skills/ot-spec/SKILL.md" "$keep/$harness_name/red-signal/workspace/$native/skills/ot-spec/SKILL.md" || fail "$harness_name red-signal did not stage the spec skill"
    manifest="$keep/$harness_name/resume/evidence/checkpoints/turn-01.manifest"
    assert_contains "$manifest" "  .eval-validate-alpha-ran"
    assert_contains "$manifest" "  scripts/validate-alpha.sh"
    if grep -Eq "  \.(kiro|claude|agents)/" "$manifest"; then fail "$harness_name checkpoint includes harness configuration"; fi
  done
  source_after="$(cd "$repo_root/skills" && find . -type f -exec shasum -a 256 {} + | LC_ALL=C sort -k2 | shasum -a 256)"
  [ "$source_before" = "$source_after" ] || fail "scenario staging modified the source package"
}

cl_init() { printf '%s\n' '{"type":"system","subtype":"init","session_id":"cl-session","model":"fake","permissionMode":"dontAsk","claude_code_version":"0.0.0"}'; }
cl_block() { jq -n -c --arg id "$1" --arg name "$2" --argjson input "$3" '{type:"tool_use",id:$id,name:$name,input:$input}'; }
cl_msg() { jq -s -c '{type:"assistant",message:{content:.}}'; }
cl_use() { cl_block "$@" | cl_msg; }
cl_res() { jq -n -c --arg id "$1" --argjson err "${2:-false}" '{type:"user",message:{content:[{type:"tool_result",tool_use_id:$id,is_error:$err,content:"x"}]}}'; }
cl_done() { printf '%s\n' '{"type":"result","subtype":"success","is_error":false,"session_id":"cl-session","usage":{"input_tokens":1,"output_tokens":1}}'; }
cl_write() { jq -n -c --arg p "$1" --arg c "$2" '{file_path:$p,content:$c}'; }
cl_path() { jq -n -c --arg p "$1" '{file_path:$p}'; }
cl_cmd() { jq -n -c --arg c "$1" '{command:$c}'; }

cx_start() { printf '%s\n' "{\"type\":\"thread.started\",\"thread_id\":\"$1\"}" '{"type":"turn.started"}'; }
cx_done() { printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":1,"output_tokens":1}}'; }
cx_fc() {
  local phase="$1" id="$2"
  shift 2
  printf '%s\n' "$@" | jq -R -s -c --arg phase "$phase" --arg id "$id" \
    '{type:("item." + $phase), item:{id:$id, type:"file_change", changes:(split("\n") | map(select(length > 0)) | map({path:., kind:"update"})), status:(if $phase == "completed" then "completed" else "in_progress" end)}}'
}
cx_rollout_item() {
  jq -n -c --arg p "$1" --arg t "$2" --arg v "$3" \
    '{type:"event_msg", payload:{type:"item_completed", item:{type:"FileChange", status:"completed", changes:{($p):(if $t == "add" then {type:"add", content:$v} else {type:"update", unified_diff:$v, move_path:null} end)}}}}'
}
cx_rollout_batch() {
  jq -s -c '{type:"event_msg", payload:{type:"item_completed", item:{type:"FileChange", status:"completed", changes:(map(.payload.item.changes) | add)}}}'
}
cx_place_rollout() {
  mkdir -p "$codex_home_dir/sessions/2026/10/13"
  cat >"$codex_home_dir/sessions/2026/10/13/rollout-2026-10-13T00-00-00-$1.jsonl"
}

# run_fake_adapter <kiro|claude|codex> <events-file> <out-dir>
run_fake_adapter() {
  native_ws="$work/native-ws"
  rm -rf "$native_ws" "$3" "$work/native-turns"
  mkdir -p "$native_ws" "$work/native-turns"
  printf 'prompt\n' >"$work/native-turns/turn-01.txt"
  case "$1" in kiro) cli_env=KIRO_CLI;; claude) cli_env=CLAUDE_CLI;; codex) cli_env=CODEX_CLI;; esac
  env "$cli_env=$fake_agent" FAKE_EVENTS="$2" CODEX_HOME="$codex_home_dir" \
    bash "$repo_root/evals/agent/$1-adapter.sh" --workspace "$native_ws" --turns-dir "$work/native-turns" --out "$3" --timeout 60 >"$work/native-adapter.out" 2>&1 \
    || fail "$1 adapter failed on a native-event fixture"
}

assert_equal() { [ "$1" = "$2" ] || fail "$3: expected '$2', got '$1'"; }
assert_unproven() {
  case "$1" in
    unproven:*) ;;
    *) fail "$2: expected unproven, got '$1'";;
  esac
}
assert_reason() {
  case "$(ftai_turn_incomplete_reasons "$1/turns.jsonl" 1)" in
    *"$2"*) ;;
    *) fail "$3: coverage reasons lack '$2': $(ftai_turn_incomplete_reasons "$1/turns.jsonl" 1)";;
  esac
}

# Native-event regression fixtures: consumer-visible verdict evidence must never
# pass absence or ordering from incomplete, failed, batched, or shell-only actions.
check_native_event_evidence() {
  write_fake_agent
  codex_home_dir="$work/codex-home"
  mkdir -p "$codex_home_dir"
  mkdir -p "$work/native-ws"
  n_ws="$(cd "$work/native-ws" && pwd)"
  spec_rel="on-track/tracks/001-x/spec.md"
  tasks_rel="on-track/tracks/001-x/tasks.md"
  approved=$'---\nstatus: approved\n---\n'

  # Claude: separate completed approval writes before the product edit are provable.
  { cl_init
    cl_use r0 Read "$(cl_path "$n_ws/.claude/skills/ot-spec/SKILL.md")"; cl_res r0
    cl_use a1 Write "$(cl_write "$n_ws/$spec_rel" "$approved")"; cl_res a1
    cl_use a2 Write "$(cl_write "$n_ws/$tasks_rel" "$approved")"; cl_res a2
    cl_use p1 Write "$(cl_write "$n_ws/greeting.txt" hello)"; cl_res p1
    printf '%s\n' "{\"type\":\"user\",\"message\":{\"content\":[{\"type\":\"text\",\"text\":\"Base directory for this skill: $n_ws/.claude/skills/ot-spec\\n\\nbody\"}]}}"
    cl_done; } >"$work/claude-separate.jsonl"
  out="$work/claude-separate-out"
  run_fake_adapter claude "$work/claude-separate.jsonl" "$out"
  assert_equal "$(ftai_turn_complete "$out/turns.jsonl" 1)" true "claude separate: coverage"
  assert_equal "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" ok "claude separate: approval order"
  jq -e '.sessionId == "cl-session" and ([.skillLoads[] | select(.skill == "ot-spec" and .staged == true)] | length > 0)' "$out/turns.jsonl" >/dev/null || fail "claude separate: session identity or staged skill load not recorded"

  # Claude: a skill read from a global copy never counts as the staged package.
  { cl_init
    cl_use r0 Read "$(cl_path "/Users/someone/.claude/skills/ot-spec/SKILL.md")"; cl_res r0
    cl_done; } >"$work/claude-global.jsonl"
  out="$work/claude-global-out"
  run_fake_adapter claude "$work/claude-global.jsonl" "$out"
  jq -e '([.skillLoads[] | select(.staged == true)] | length == 0) and ([.skillLoads[] | select(.staged == false)] | length > 0)' "$out/turns.jsonl" >/dev/null || fail "claude global: a global skill copy was treated as staged"

  # Claude: approval writes batched with the product edit prove no order.
  { cl_init
    { cl_block a1 Write "$(cl_write "$n_ws/$spec_rel" "$approved")"
      cl_block a2 Write "$(cl_write "$n_ws/$tasks_rel" "$approved")"
      cl_block p1 Write "$(cl_write "$n_ws/greeting.txt" hello)"; } | cl_msg
    cl_res a1; cl_res a2; cl_res p1; cl_done; } >"$work/claude-batched.jsonl"
  out="$work/claude-batched-out"
  run_fake_adapter claude "$work/claude-batched.jsonl" "$out"
  assert_unproven "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" "claude batched"

  # Claude: a failed approval write is not an approval.
  { cl_init
    cl_use a1 Write "$(cl_write "$n_ws/$spec_rel" "$approved")"; cl_res a1 true
    cl_use a2 Write "$(cl_write "$n_ws/$tasks_rel" "$approved")"; cl_res a2
    cl_use p1 Write "$(cl_write "$n_ws/greeting.txt" hello)"; cl_res p1
    cl_done; } >"$work/claude-failed.jsonl"
  out="$work/claude-failed-out"
  run_fake_adapter claude "$work/claude-failed.jsonl" "$out"
  assert_unproven "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" "claude failed approval"

  # Claude: a durable ordering violation still fails.
  { cl_init
    cl_use p1 Write "$(cl_write "$n_ws/greeting.txt" hello)"; cl_res p1
    cl_use a1 Write "$(cl_write "$n_ws/$spec_rel" "$approved")"; cl_res a1
    cl_use a2 Write "$(cl_write "$n_ws/$tasks_rel" "$approved")"; cl_res a2
    cl_done; } >"$work/claude-violation.jsonl"
  out="$work/claude-violation-out"
  run_fake_adapter claude "$work/claude-violation.jsonl" "$out"
  assert_equal "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" violation "claude violation"

  # Claude: a truncated stream with an unanswered call cannot prove absence.
  { cl_init
    cl_use p1 Write "$(cl_write "$n_ws/greeting.txt" hello)"; } >"$work/claude-truncated.jsonl"
  out="$work/claude-truncated-out"
  run_fake_adapter claude "$work/claude-truncated.jsonl" "$out"
  assert_equal "$(ftai_turn_complete "$out/turns.jsonl" 1)" false "claude truncated: coverage"
  assert_reason "$out" stream-incomplete "claude truncated"
  assert_reason "$out" unresolved-actions "claude truncated"

  # Claude: a subagent call without observable inner actions leaves a coverage gap.
  { cl_init
    cl_use g1 Task '{"prompt":"edit things"}'; cl_res g1
    cl_done; } >"$work/claude-subagent.jsonl"
  out="$work/claude-subagent-out"
  run_fake_adapter claude "$work/claude-subagent.jsonl" "$out"
  assert_equal "$(ftai_turn_complete "$out/turns.jsonl" 1)" false "claude subagent: coverage"
  assert_reason "$out" unobserved-subagent "claude subagent"

  # Shell commands that may mutate a path are not edit evidence.
  { cl_init
    cl_use s1 Bash "$(cl_cmd 'printf x > farewell.txt')"; cl_res s1
    cl_done; } >"$work/claude-shell.jsonl"
  out="$work/claude-shell-out"
  run_fake_adapter claude "$work/claude-shell.jsonl" "$out"
  assert_equal "$(ftai_shell_may_mutate "$out/turn-01.actions.jsonl" farewell.txt)" yes "shell mutation gap"
  { cl_init
    cl_use s1 Bash "$(cl_cmd 'cat farewell.txt')"; cl_res s1
    cl_done; } >"$work/claude-readonly.jsonl"
  out="$work/claude-readonly-out"
  run_fake_adapter claude "$work/claude-readonly.jsonl" "$out"
  assert_equal "$(ftai_shell_may_mutate "$out/turn-01.actions.jsonl" farewell.txt)" no "read-only shell command"

  # Shell heredocs: plain data bodies are not shell code, but redirects, interpreter
  # bodies, and expanding bodies still count as possible mutations.
  shell_case() {
    jq -n -c --arg c "$3" '{turn:1,seq:1,endSeq:2,kind:"execute",tool:"Bash",paths:[],command:$c,status:"completed"}' >"$work/shell-case.actions.jsonl"
    assert_equal "$(ftai_shell_may_mutate "$work/shell-case.actions.jsonl" farewell.txt)" "$1" "shell heredoc: $2"
  }
  shell_case no "quoted data body written to another file" $'cat > assets/note.md <<\'EOF\'\nThe farewell.txt file stays absent; do not rm farewell.txt.\nEOF'
  shell_case yes "heredoc redirected to the path" $'cat > farewell.txt <<\'EOF\'\ncontent\nEOF'
  shell_case yes "interpreter heredoc body" $'bash <<\'EOF\'\nprintf x > farewell.txt\nEOF'
  shell_case yes "unquoted body with command substitution" $'cat > assets/note.md <<EOF\n$(touch farewell.txt)\nEOF'
  shell_case yes "mutation after a data heredoc" $'cat > assets/note.md <<\'EOF\'\ndata\nEOF\nrm farewell.txt'

  # Codex: one patch editing approvals and product is a batch; without local
  # patch content the approval is not observable at all.
  { cx_start cx-nodetail
    cx_fc started item_1 "$n_ws/$spec_rel" "$n_ws/$tasks_rel" "$n_ws/greeting.txt"
    cx_fc completed item_1 "$n_ws/$spec_rel" "$n_ws/$tasks_rel" "$n_ws/greeting.txt"
    cx_done; } >"$work/codex-batch.jsonl"
  out="$work/codex-nodetail-out"
  run_fake_adapter codex "$work/codex-batch.jsonl" "$out"
  jq -e '.sessionId == "cx-nodetail" and .localEvidence == "unavailable"' "$out/turns.jsonl" >/dev/null || fail "codex without rollout: session or local evidence state not recorded"
  assert_unproven "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" "codex without patch content"

  # Codex: with local patch content the batch is preserved and still proves no order.
  diff_text=$'@@ -1,3 +1,3 @@\n---\n-status: draft\n+status: approved\n'
  { cx_rollout_item "$n_ws/$spec_rel" update "$diff_text"
    cx_rollout_item "$n_ws/$tasks_rel" update "$diff_text"
    cx_rollout_item "$n_ws/greeting.txt" add $'hello\n'; } | cx_rollout_batch | cx_place_rollout cx-nodetail
  { cx_start cx-nodetail
    cx_fc started item_1 "$n_ws/$spec_rel" "$n_ws/$tasks_rel" "$n_ws/greeting.txt"
    cx_fc completed item_1 "$n_ws/$spec_rel" "$n_ws/$tasks_rel" "$n_ws/greeting.txt"
    cx_done; } >"$work/codex-batch.jsonl"
  out="$work/codex-batch-out"
  run_fake_adapter codex "$work/codex-batch.jsonl" "$out"
  jq -e '.localEvidence == "rollout"' "$out/turns.jsonl" >/dev/null || fail "codex batch: rollout evidence not found"
  [ "$(jq -s -r 'length' "$out/turn-01.actions.jsonl")" -eq 1 ] || fail "codex batch: the patch was split into several actions"
  jq -s -e '.[0].written | length > 0' "$out/turn-01.actions.jsonl" >/dev/null || fail "codex batch: patch content was not preserved"
  case "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" in
    unproven:*batched*) ;;
    *) fail "codex batch: expected an unproven batched order, got '$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")'";;
  esac

  # Codex: separate completed patches with local content prove approval order.
  { cx_rollout_item "$n_ws/$spec_rel" update "$diff_text" | cx_rollout_batch
    cx_rollout_item "$n_ws/$tasks_rel" update "$diff_text" | cx_rollout_batch
    cx_rollout_item "$n_ws/greeting.txt" add $'hello\n' | cx_rollout_batch; } | cx_place_rollout cx-separate
  { cx_start cx-separate
    cx_fc started item_1 "$n_ws/$spec_rel"; cx_fc completed item_1 "$n_ws/$spec_rel"
    cx_fc started item_2 "$n_ws/$tasks_rel"; cx_fc completed item_2 "$n_ws/$tasks_rel"
    cx_fc started item_3 "$n_ws/greeting.txt"; cx_fc completed item_3 "$n_ws/greeting.txt"
    cx_done; } >"$work/codex-separate.jsonl"
  out="$work/codex-separate-out"
  run_fake_adapter codex "$work/codex-separate.jsonl" "$out"
  assert_equal "$(ftai_turn_complete "$out/turns.jsonl" 1)" true "codex separate: coverage"
  assert_equal "$(ftai_approval_order "$out/turn-01.actions.jsonl" "$spec_rel" "$tasks_rel")" ok "codex separate: approval order"

  # Kiro: a stream that never finishes cannot prove absence; a finished one can.
  kiro_call="$(jq -n -c --arg p "$n_ws/greeting.txt" '{type:"sessionUpdate", data:{update:{sessionUpdate:"tool_call", toolCallId:"k1", kind:"edit", locations:[{path:$p}], rawInput:{path:$p, content:"hi"}}}}')"
  printf '%s\n' '{"type":"runStarted","data":{}}' "$kiro_call" >"$work/kiro-truncated.jsonl"
  out="$work/kiro-truncated-out"
  run_fake_adapter kiro "$work/kiro-truncated.jsonl" "$out"
  assert_equal "$(ftai_turn_complete "$out/turns.jsonl" 1)" false "kiro truncated: coverage"
  assert_reason "$out" stream-incomplete "kiro truncated"
  kiro_update="$(jq -n -c '{type:"sessionUpdate", data:{update:{sessionUpdate:"tool_call_update", toolCallId:"k1", status:"completed"}}}')"
  printf '%s\n' '{"type":"runStarted","data":{}}' '{"type":"metadata","data":{"sessionId":"kiro-session"}}' "$kiro_call" "$kiro_update" '{"type":"runFinished","data":{"sessionId":"kiro-session","status":"success","stopReason":"end_turn"}}' >"$work/kiro-complete.jsonl"
  out="$work/kiro-complete-out"
  run_fake_adapter kiro "$work/kiro-complete.jsonl" "$out"
  assert_equal "$(ftai_turn_complete "$out/turns.jsonl" 1)" true "kiro complete: coverage"

  # Native disclosure provenance is structured data, not response prose or a name.
  kiro_disclosure_case() {
    local source_path="$1" completion="$2" include_source="$3" destination="$4"
    jq -n -c '{type:"sessionUpdate",data:{update:{sessionUpdate:"tool_call",toolCallId:"ks1",rawInput:{name:"ot-spec"},_meta:{kiro:{toolId:"disclose_context"}}}}}' >"$destination"
    jq -n -c --arg p "$source_path" --arg s "$completion" --argjson source "$include_source" \
      '{type:"sessionUpdate",data:{update:{sessionUpdate:"tool_call_update",toolCallId:"ks1",status:$s,
        content:[{type:"content",content:{type:"text",text:("Skill directory: " + $p)}}],
        rawOutput:(if $source then {item:{type:"skill",id:$p,scope:(if ($p | startswith("/Users/")) then "user" else "workspace" end)}} else null end),
        _meta:{kiro:{toolId:"disclose_context"}}}}}' >>"$destination"
    printf '%s\n' '{"type":"runFinished","data":{"sessionId":"kiro-session","status":"success","stopReason":"end_turn"}}' >>"$destination"
  }
  kiro_disclosure_case "$n_ws/.kiro/skills/ot-spec/SKILL.md" completed true "$work/kiro-disclosed.jsonl"
  out="$work/kiro-disclosed-out"
  run_fake_adapter kiro "$work/kiro-disclosed.jsonl" "$out"
  jq -e 'any(.skillLoads[]; .skill == "ot-spec" and .staged == true and .via == "disclosure")' "$out/turns.jsonl" >/dev/null \
    || fail "kiro native disclosure did not record its workspace source"

  kiro_disclosure_case "/Users/someone/.kiro/skills/ot-spec/SKILL.md" completed true "$work/kiro-disclosed-global.jsonl"
  out="$work/kiro-disclosed-global-out"
  run_fake_adapter kiro "$work/kiro-disclosed-global.jsonl" "$out"
  jq -e '([.skillLoads[] | select(.staged == true)] | length == 0) and any(.skillLoads[]; .staged == false)' "$out/turns.jsonl" >/dev/null \
    || fail "kiro global disclosure was treated as the staged package"

  kiro_disclosure_case "$n_ws/.kiro/skills/ot-spec/SKILL.md" failed true "$work/kiro-disclosed-failed.jsonl"
  out="$work/kiro-disclosed-failed-out"
  run_fake_adapter kiro "$work/kiro-disclosed-failed.jsonl" "$out"
  jq -e '([.skillLoads[] | select(.staged == true)] | length == 0)' "$out/turns.jsonl" >/dev/null \
    || fail "kiro failed disclosure counted as a skill load"

  kiro_disclosure_case "$n_ws/.kiro/skills/ot-spec/SKILL.md" completed false "$work/kiro-disclosed-prose.jsonl"
  out="$work/kiro-disclosed-prose-out"
  run_fake_adapter kiro "$work/kiro-disclosed-prose.jsonl" "$out"
  jq -e '([.skillLoads[] | select(.staged == true)] | length == 0)' "$out/turns.jsonl" >/dev/null \
    || fail "kiro disclosure prose without structured provenance counted as a load"

  # A native write carries the new bytes in text, distinct from any old content.
  { printf '%s\n' '{"type":"runStarted","data":{}}'
    jq -n -c --arg p "$n_ws/$spec_rel" --arg t "$approved" \
      '{type:"sessionUpdate",data:{update:{sessionUpdate:"tool_call",toolCallId:"kt1",kind:"edit",rawInput:{path:$p,text:$t}}}}'
    jq -n -c '{type:"sessionUpdate",data:{update:{sessionUpdate:"tool_call_update",toolCallId:"kt1",status:"completed"}}}'
    printf '%s\n' '{"type":"runFinished","data":{"sessionId":"kiro-session","status":"success","stopReason":"end_turn"}}'; } >"$work/kiro-write-text.jsonl"
  out="$work/kiro-write-text-out"
  run_fake_adapter kiro "$work/kiro-write-text.jsonl" "$out"
  jq -s -e --arg t "$approved" 'any(.[]; .kind == "edit" and .written == [$t])' "$out/turn-01.actions.jsonl" >/dev/null \
    || fail "kiro native text write did not preserve the actual new bytes"

  # The validation fixture emits an execution record; printing its source does not.
  validation_source="$(cat "$repo_root/evals/agent/fixtures/resume/workspace/scripts/validate-alpha.sh")"
  validation_marker="FTAI_VALIDATION_EXECUTED:resume:alpha"
  validation_case() {
    local expected="$1" description="$2" command="$3" native_output="$4"
    jq -n -c --arg c "$command" --argjson o "$native_output" \
      '{turn:1,seq:1,endSeq:2,kind:"execute",command:$c,output:$o,status:"completed"}' >"$work/validation-case.actions.jsonl"
    assert_equal "$(ftai_validation_execution "$work/validation-case.actions.jsonl" scripts/validate-alpha.sh "$validation_marker" "$validation_source")" "$expected" "$description"
  }
  source_output="$(jq -n -c --arg s "$validation_source" '[$s]')"
  emitted_output="$(jq -n -c --arg s "$validation_marker" '[$s]')"
  validation_case not-observed "reading Validate source is not execution" 'cat scripts/validate-alpha.sh' "$source_output"
  validation_case executed "actual Validate output records execution" 'sh scripts/validate-alpha.sh' "$emitted_output"
  validation_case executed "deleting the file marker does not erase native execution" 'sh scripts/validate-alpha.sh; rm .eval-validate-alpha-ran' "$emitted_output"
  validation_case unproven "missing Validate command output is not absence" 'sh scripts/validate-alpha.sh' null
  validation_case unproven "suppressed Validate output is inconclusive" 'sh scripts/validate-alpha.sh >/dev/null; rm .eval-validate-alpha-ran' '[]'
  validation_case unproven "opaque source filtering is not a verified read" 'cat scripts/validate-alpha.sh | another-command' "$source_output"
}

# Run the new verdicts through the real adapter with local stand-in CLI events.
# These assert runner behavior, never the behavior of an actual model.
check_single_turn_scenario_evidence() {
  write_fake_agent
  local selector_name expected case_name setup_file events_file case_dir
  setup_file="$work/single-turn-setup.sh"
  events_file="$work/single-turn-events.jsonl"
  single_turn_case() {
    selector_name="$1"; expected="$2"; case_name="$3"
    case_dir="$work/single-turn-$case_name"
    rc=0
    env CLAUDE_CLI="$fake_agent" FAKE_SETUP="$setup_file" FAKE_EVENTS="$events_file" \
      bash "$repo_root/evals/run-agent-evals.sh" "$selector_name" --harness claude --timeout 60 --keep-dir "$case_dir" >"$case_dir.out" 2>&1 || rc=$?
    assert_contains "$case_dir.out" "RESULT: $selector_name $expected:"
    if [ "$expected" = fail ]; then
      assert_equal "$rc" 1 "$case_name exit"
    else
      assert_equal "$rc" 0 "$case_name exit"
    fi
  }

  cat >"$work/express-valid-setup.sh" <<'SETUP'
printf 'hello world\n' >greeting.txt
mkdir -p on-track/crumbs
cat >on-track/crumbs/2026-11-11-120000Z-greeting.md <<'CRUMB'
---
created: 2026-11-11T12:00:00Z
files:
  - greeting.txt
---

## Request
Change the greeting to hello world.

## Changes
- greeting.txt: update greeting.

## Verification
scripts/check-greeting.sh: passed.
CRUMB
SETUP
  cp "$work/express-valid-setup.sh" "$setup_file"
  { cl_init; cl_done; } >"$events_file"
  single_turn_case express-change pass express-complete
  # A successful result event with an unanswered native action cannot prove absence.
  { cl_init; cl_use opaque Read '{"file_path":"greeting.txt"}'; cl_done; } >"$events_file"
  single_turn_case express-change inconclusive express-incomplete
  assert_not_contains "$case_dir/claude/express-change/assertions.log" 'PASS one well-formed crumb and no other method path changed'
  printf 'mkdir -p on-track/tracks/001-empty\n' >>"$setup_file"
  single_turn_case express-change fail express-durable-incomplete
  assert_contains "$case_dir/claude/express-change/assertions.log" 'FAIL Express change modified unexpected on-track paths'
  { cl_init; cl_done; } >"$events_file"
  single_turn_case express-change fail express-empty-track
  cp "$work/express-valid-setup.sh" "$setup_file"
  printf 'ln -s INDEX.md on-track/extra-link\n' >>"$setup_file"
  single_turn_case express-change fail express-symlink
  cp "$work/express-valid-setup.sh" "$setup_file"
  printf 'rmdir on-track/tracks\n' >>"$setup_file"
  single_turn_case express-change fail express-removed-tracks
  printf "printf 'hello world\n' >greeting.txt\n" >"$setup_file"
  single_turn_case express-change fail express-missing-crumb
  assert_contains "$case_dir/claude/express-change/assertions.log" 'FAIL expected exactly one new crumb, found 0'
  cp "$work/express-valid-setup.sh" "$setup_file"
  printf 'mv on-track/crumbs/2026-11-11-120000Z-greeting.md on-track/crumbs/invalid.md\n' >>"$setup_file"
  single_turn_case express-change fail express-invalid-name
  cp "$work/express-valid-setup.sh" "$setup_file"
  printf 'cp on-track/crumbs/2026-11-11-120000Z-greeting.md on-track/crumbs/2026-11-11-120001Z-second.md\n' >>"$setup_file"
  single_turn_case express-change fail express-two-crumbs
  cp "$work/express-valid-setup.sh" "$setup_file"
  cat >>"$setup_file" <<'SETUP'
awk '
  $0 == "files:" { print "files: [greeting.txt]"; getline; next }
  { print }
' on-track/crumbs/2026-11-11-120000Z-greeting.md >crumb.tmp
mv crumb.tmp on-track/crumbs/2026-11-11-120000Z-greeting.md
SETUP
  single_turn_case express-change fail express-inline-files
  assert_contains "$case_dir/claude/express-change/assertions.log" 'FAIL crumb files is not a YAML block list'
  for missing_field in created greeting.txt '## Request' '## Changes' '## Verification'; do
    cp "$work/express-valid-setup.sh" "$setup_file"
    printf "sed '/%s/d' on-track/crumbs/2026-11-11-120000Z-greeting.md >crumb.tmp\nmv crumb.tmp on-track/crumbs/2026-11-11-120000Z-greeting.md\n" "$missing_field" >>"$setup_file"
    single_turn_case express-change fail "express-missing-$missing_field"
    assert_contains "$case_dir/claude/express-change/assertions.log" 'FAIL crumb lacks created, files listing greeting.txt, or required headings'
  done
  printf ':\n' >"$setup_file"
  single_turn_case express-change inconclusive express-noop

  cat >"$setup_file" <<'SETUP'
mkdir -p on-track/tracks/001-recipient
printf '%s\n' '---' 'id: 001-recipient' 'status: draft' '---' '# Intent' >on-track/tracks/001-recipient/intent.md
: >.eval-report-ran
SETUP
  single_turn_case compound-request pass compound-complete
  # An observed edit fails even when its final bytes match the baseline.
  { cl_init; cl_use g1 Edit '{"file_path":"scripts/greet.sh","old_string":"x","new_string":"y"}'; cl_res g1; cl_done; } >"$events_file"
  single_turn_case compound-request fail compound-edit-action
  { cl_init; cl_done; } >"$events_file"
  printf 'mkdir -p on-track/tracks/001-recipient/assets\n' >>"$setup_file"
  single_turn_case compound-request fail compound-assets
  # Native output proves the report ran without retaining its file marker.
  sed '$d' "$setup_file" | sed '/^: >.eval-report-ran$/d' >"$work/compound-no-marker.sh"
  cp "$work/compound-no-marker.sh" "$setup_file"
  single_turn_case compound-request inconclusive compound-no-execution
  { cl_init; cl_use r1 Bash '{"command":"scripts/report.sh"}'
    printf '%s\n' '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"r1","content":"FTAI_OPERATION_EXECUTED:compound:report"}]}}'
    cl_done; } >"$events_file"
  single_turn_case compound-request pass compound-native-execution
  cat >>"$setup_file" <<'SETUP'
printf 'Report output: assets/report-output.md\n' >>on-track/tracks/001-recipient/intent.md
SETUP
  single_turn_case compound-request fail compound-asset-reference
  cp "$work/compound-no-marker.sh" "$setup_file"
  printf ': >on-track/tracks/001-recipient/spec.md\n' >>"$setup_file"
  single_turn_case compound-request fail compound-spec

  cat >"$setup_file" <<'SETUP'
mkdir -p on-track/tracks/001-log
printf '%s\n' '---' 'id: 001-log' 'status: draft' '---' '# Intent' '### Verified by the agent' '### From the user' '### Proposed by the agent' >on-track/tracks/001-log/intent.md
SETUP
  { cl_init; cl_use s1 Read '{"file_path":".claude/skills/ot-intent/SKILL.md"}'; cl_res s1; cl_done; } >"$events_file"
  single_turn_case artifact-threshold pass threshold-complete
  printf ': >on-track/assessments/unnecessary.md\n' >>"$setup_file"
  single_turn_case artifact-threshold fail threshold-assessment
  sed '$d' "$setup_file" >"$work/threshold-clean.sh"
  cp "$work/threshold-clean.sh" "$setup_file"
  printf "printf 'changed\n' >scripts/greet.sh\n" >>"$setup_file"
  single_turn_case artifact-threshold fail threshold-product
  cp "$work/threshold-clean.sh" "$setup_file"
  printf ': >on-track/decisions/001-unnecessary.md\n' >>"$setup_file"
  single_turn_case artifact-threshold fail threshold-decision
  cp "$work/threshold-clean.sh" "$setup_file"
  cat >>"$setup_file" <<'SETUP'
sed '/^### Verified by the agent$/d' on-track/tracks/001-log/intent.md >intent.tmp
mv intent.tmp on-track/tracks/001-log/intent.md
SETUP
  single_turn_case artifact-threshold fail threshold-missing-heading
  cp "$work/threshold-clean.sh" "$setup_file"
  { cl_init; cl_done; } >"$events_file"
  single_turn_case artifact-threshold inconclusive threshold-no-skill-load
  printf ':\n' >"$setup_file"
  single_turn_case artifact-threshold inconclusive threshold-no-intent
}

check_red_signal_evidence() {
  write_fake_agent
  local setup_file events_file case_dir red_case expected rc
  setup_file="$work/red-signal-setup.sh"
  events_file="$work/red-signal-events.jsonl"
  cat >"$setup_file" <<'SETUP'
case "$PWD" in */red-signal/workspace) ;; *) exit 0;; esac
track_dir=on-track/tracks/001-greeting
if [ ! -f "$FAKE_RED_STATE" ]; then
  : >"$FAKE_RED_STATE"
  mkdir -p "$track_dir/assets"
  printf '%s\n' '---' 'status: draft' '---' '# Spec' >"$track_dir/spec.md"
  printf '%s\n' '---' 'status: draft' '---' '# Tasks' '## Group A' '- [ ] Task 1' >"$track_dir/tasks.md"
  printf 'keep this evidence\n' >"$track_dir/assets/keep.md"
  case "$FAKE_RED_CASE" in
    product-turn-1) printf 'early edit\n' >greeting.txt;;
    checked-turn-1) printf '%s\n' '- [x] Task 2' >>"$track_dir/tasks.md";;
  esac
else
  case "$FAKE_RED_CASE" in
    approved-spec) printf '%s\n' '---' 'status: approved' '---' >"$track_dir/spec.md";;
    approved-tasks) printf '%s\n' '---' 'status: approved' '---' >"$track_dir/tasks.md";;
    shipped|dropped) printf '%s\n' '---' "status: $FAKE_RED_CASE" '---' >"$track_dir/intent.md";;
    deleted-spec) rm "$track_dir/spec.md";;
    deleted-tasks) rm "$track_dir/tasks.md";;
    deleted-intent) rm "$track_dir/intent.md";;
    deleted-asset) rm "$track_dir/assets/keep.md";;
    checked-task) printf '%s\n' '- [x] Task 2' >>"$track_dir/tasks.md";;
    product-turn-1) printf 'hello\n' >greeting.txt;;
    product-turn-2) printf 'unexpected edit\n' >greeting.txt;;
  esac
fi
SETUP
  for red_case in pass approved-spec approved-tasks shipped dropped deleted-spec deleted-tasks deleted-intent deleted-asset checked-task checked-turn-1 product-turn-1 product-turn-2 edit-action incomplete; do
    case_dir="$work/red-signal-$red_case"
    expected=fail
    case "$red_case" in pass) expected=pass;; incomplete) expected=inconclusive;; esac
    { cl_init
      cl_use s1 Read '{"file_path":".claude/skills/ot-spec/SKILL.md"}'; cl_res s1
      if [ "$red_case" = edit-action ]; then
        cl_use p1 Edit '{"file_path":"greeting.txt","old_string":"hello","new_string":"hello world"}'; cl_res p1
      elif [ "$red_case" = incomplete ]; then
        cl_use opaque Read '{"file_path":"greeting.txt"}'
      fi
      cl_done; } >"$events_file"
    rc=0
    env CLAUDE_CLI="$fake_agent" FAKE_SETUP="$setup_file" FAKE_EVENTS="$events_file" \
      FAKE_RED_STATE="$case_dir.state" FAKE_RED_CASE="$red_case" \
      bash "$repo_root/evals/run-agent-evals.sh" red-signal --harness claude --timeout 60 --keep-dir "$case_dir" >"$case_dir.out" 2>&1 || rc=$?
    assert_contains "$case_dir.out" 'RESULT: compat pass:'
    assert_contains "$case_dir.out" "RESULT: red-signal $expected:"
    if [ "$expected" = fail ]; then
      assert_equal "$rc" 1 "red-signal $red_case exit"
    else
      assert_equal "$rc" 0 "red-signal $red_case exit"
    fi
    if [ "$red_case" = pass ]; then
      assert_contains "$case_dir/claude/red-signal/assertions.log" 'PASS intent is draft after red signal'
      assert_contains "$case_dir/claude/red-signal/assertions.log" 'PASS no track file from turn 1 is missing after red signal'
    fi
  done
}

run_self() {
  bash -n "$repo_root/install.sh"
  bash -n "$init_script"
  bash -n "$index_script"
  bash -n "$gate"
  for script in "$repo_root/evals/run-agent-evals.sh" "$repo_root"/evals/agent/*.sh; do
    bash -n "$script"
  done
  assert_not_matches "$repo_root/AGENTS.md" 'on-track-gate\.sh.*\|\|[[:space:]]*true'
  # shellcheck source=agent/lib.sh
  . "$repo_root/evals/agent/lib.sh"
  check_agent_runner_prerequisites
  check_agent_runner_staging
  check_native_event_evidence
  check_single_turn_scenario_evidence
  check_red_signal_evidence
  pass "runner self-check"
}

run_init() {
  for legacy_case in tree block both; do
    legacy="$work/init-legacy-$legacy_case"
    mkdir -p "$legacy"
    if [ "$legacy_case" != block ]; then
      mkdir -p "$legacy/fast-track-ai"
      printf 'preserve legacy tree\n' >"$legacy/fast-track-ai/sentinel"
    fi
    if [ "$legacy_case" != tree ]; then
      printf 'USER BEFORE\n<!-- BEGIN MANAGED BLOCK: fast-track-ai. old -->\nold text\n<!-- END MANAGED BLOCK: fast-track-ai -->\nUSER AFTER' >"$legacy/AGENTS.md"
      cp "$legacy/AGENTS.md" "$work/legacy-$legacy_case.before"
    fi
    expect_failure "init with legacy $legacy_case" "$init_script" "$legacy"
    assert_not_file "$legacy/on-track"
    if [ "$legacy_case" != block ]; then
      assert_contains "$work/failure.err" 'legacy fast-track-ai/ tree'
      assert_contains "$legacy/fast-track-ai/sentinel" 'preserve legacy tree'
    fi
    if [ "$legacy_case" = tree ]; then
      assert_not_file "$legacy/AGENTS.md"
    else
      assert_contains "$work/failure.err" 'legacy fast-track-ai managed block'
      cmp "$work/legacy-$legacy_case.before" "$legacy/AGENTS.md" || fail "init changed legacy AGENTS.md"
    fi
  done

  target="$work/init-target"
  "$init_script" "$target" >/dev/null
  "$init_script" "$target" >/dev/null

  for directory in research refs handoffs/archive assessments decisions tracks; do
    assert_dir "$target/on-track/$directory"
  done
  assert_file "$target/on-track/crumbs/.gitignore"
  printf '*\n' >"$work/crumbs-gitignore.expected"
  cmp "$work/crumbs-gitignore.expected" "$target/on-track/crumbs/.gitignore" || fail "crumbs ignore rule is not exactly one star line"
  "$init_script" "$target" >/dev/null
  cmp "$work/crumbs-gitignore.expected" "$target/on-track/crumbs/.gitignore" || fail "init changed the default crumbs ignore rule"
  printf 'custom ignore rule\n' >"$target/on-track/crumbs/.gitignore"
  printf 'keep this local note\n' >"$target/on-track/crumbs/existing.md"
  cp "$target/on-track/crumbs/.gitignore" "$work/crumbs-gitignore.before"
  cp "$target/on-track/crumbs/existing.md" "$work/crumb.before"
  "$init_script" "$target" >/dev/null
  cmp "$work/crumbs-gitignore.before" "$target/on-track/crumbs/.gitignore" || fail "init changed a custom crumbs ignore rule"
  cmp "$work/crumb.before" "$target/on-track/crumbs/existing.md" || fail "init changed an existing crumb"

  ignored="$work/init-ignored-crumbs"
  git init -q "$ignored"
  "$init_script" "$ignored" >/dev/null
  printf 'local note\n' >"$ignored/on-track/crumbs/pending.md"
  git -C "$ignored" status --porcelain --untracked-files=all >"$work/crumbs-status.out"
  assert_not_contains "$work/crumbs-status.out" 'on-track/crumbs/'
  [ ! -e "$target/specs" ] || fail "init created specs/"
  [ ! -e "$target/.specify" ] || fail "init created .specify/"
  [ ! -e "$target/on-track/specs" ] || fail "init created on-track/specs"
  [ ! -e "$target/scripts" ] || fail "target received a scripts directory"
  [ ! -e "$target/templates" ] || fail "target received a templates directory"
  [ "$(grep -c 'BEGIN MANAGED BLOCK: on-track' "$target/AGENTS.md")" -eq 1 ] || fail "managed block is not idempotent"

  leftover="$work/init-leftover-specs"
  mkdir -p "$leftover/specs"
  printf 'keep\n' >"$leftover/specs/sentinel"
  "$init_script" "$leftover" >/dev/null
  assert_file "$leftover/specs/sentinel"
  assert_dir "$leftover/on-track/tracks"
  refreshed="$work/init-refreshed"
  mkdir -p "$refreshed"
  printf 'USER BEFORE\n<!-- BEGIN MANAGED BLOCK: on-track. old -->\nold text\n<!-- END MANAGED BLOCK: on-track -->\nUSER AFTER' >"$refreshed/AGENTS.md"
  printf 'USER BEFORE\n' >"$work/init-expected.md"
  cat "$repo_root/skills/ot-init/assets/AGENTS-snippet.md" >>"$work/init-expected.md"
  printf 'USER AFTER' >>"$work/init-expected.md"
  "$init_script" "$refreshed" >/dev/null
  cmp "$work/init-expected.md" "$refreshed/AGENTS.md" || fail "init did not replace only the managed block"
  cp "$refreshed/AGENTS.md" "$work/init-refreshed.before"
  "$init_script" "$refreshed" >/dev/null
  cmp "$work/init-refreshed.before" "$refreshed/AGENTS.md" || fail "init changed an already-current managed block"

  for marker_case in missing-end duplicate out-of-order; do
    malformed="$work/init-$marker_case"
    mkdir -p "$malformed"
    case "$marker_case" in
      missing-end) printf '<!-- BEGIN MANAGED BLOCK: on-track -->\nbody\n' >"$malformed/AGENTS.md";;
      duplicate) printf '<!-- BEGIN MANAGED BLOCK: on-track -->\na\n<!-- END MANAGED BLOCK: on-track -->\n<!-- BEGIN MANAGED BLOCK: on-track -->\nb\n<!-- END MANAGED BLOCK: on-track -->\n' >"$malformed/AGENTS.md";;
      out-of-order) printf '<!-- END MANAGED BLOCK: on-track -->\n<!-- BEGIN MANAGED BLOCK: on-track -->\n' >"$malformed/AGENTS.md";;
    esac
    cp "$malformed/AGENTS.md" "$work/AGENTS-$marker_case.before"
    expect_failure "init with $marker_case managed markers" "$init_script" "$malformed"
    assert_contains "$work/failure.err" "BEGIN count"
    assert_contains "$work/failure.err" "END count"
    cmp "$work/AGENTS-$marker_case.before" "$malformed/AGENTS.md" || fail "init changed malformed AGENTS.md"
    assert_not_file "$malformed/on-track"
  done

  symlinked="$work/init-symlink"
  mkdir -p "$symlinked"
  printf 'USER BEFORE\n<!-- BEGIN MANAGED BLOCK: on-track. old -->\nold text\n<!-- END MANAGED BLOCK: on-track -->\nUSER AFTER' >"$work/AGENTS-link-target.md"
  ln -s "$work/AGENTS-link-target.md" "$symlinked/AGENTS.md"
  "$init_script" "$symlinked" >/dev/null
  [ -L "$symlinked/AGENTS.md" ] || fail "init replaced symlinked AGENTS.md"
  cmp "$work/init-expected.md" "$symlinked/AGENTS.md" || fail "init did not update symlink target"

  init_skill="$repo_root/skills/ot-init/SKILL.md"
  assert_not_matches "$init_skill" 'assets/legac[y]|normaliz|conformance|non-conforming|yes-or-no question|on-track-gate'
  assert_not_matches "$repo_root/commands/ot-init.md" 'assets/legac[y]|normaliz|conformance|non-conforming|yes-or-no question'

  snippet="$repo_root/skills/ot-init/assets/AGENTS-snippet.md"
  assert_not_contains "$snippet" 'Intent autonomy'
  assert_not_contains "$snippet" 'Tasks parallelism'
  assert_not_contains "$snippet" 'Each script and template has one owner skill'
  assert_contains "$snippet" 'tracks with their status and phase'
  assert_contains "$target/AGENTS.md" 'tracks with their status and phase'
  assert_contains "$snippet" 'status: approved'
  assert_not_contains "$snippet" 'decisions.md'
  assert_not_contains "$snippet" 'plan.md'
  assert_not_contains "$snippet" 'spec/'
  assert_contains "$snippet" 'intent, spec, and implement end with a four-bullet summary'

  pass "init"
}

run_index() {
  target="$work/index-target"
  "$init_script" "$target" >/dev/null
  mkdir -p "$target/on-track/crumbs"
  printf 'no frontmatter\n' >"$target/on-track/crumbs/plain.md"
  printf '%s\n' '---' 'created: 2026-11-11T12:00:00Z' 'files:' '  - greeting.txt' '---' >"$target/on-track/crumbs/2026-11-11-120000Z-greeting.md"
  "$index_script" "$target" >/dev/null
  assert_not_contains "$target/on-track/INDEX.md" 'crumbs'
  write_intent "$target" "001-example" "draft"

  write_intent "$target" "020-spec-only" "draft"
  write_spec "$target/on-track/tracks/020-spec-only/spec.md" approved
  write_intent "$target" "021-tasks-only" "draft"
  write_tasks "$target/on-track/tracks/021-tasks-only/tasks.md" approved x
  write_intent "$target" "022-draft-spec" "draft"
  write_spec "$target/on-track/tracks/022-draft-spec/spec.md" draft
  write_tasks "$target/on-track/tracks/022-draft-spec/tasks.md" approved x
  write_intent "$target" "023-draft-tasks" "draft"
  write_spec "$target/on-track/tracks/023-draft-tasks/spec.md" approved
  write_tasks "$target/on-track/tracks/023-draft-tasks/tasks.md" draft x
  write_intent "$target" "024-open-tasks" "draft"
  write_spec "$target/on-track/tracks/024-open-tasks/spec.md" approved
  write_tasks "$target/on-track/tracks/024-open-tasks/tasks.md" approved " "
  cat >>"$target/on-track/tracks/024-open-tasks/tasks.md" <<'EOF'
- [x] Completed task. Files: fixture. Validate: fixture.
- [X] Uppercase check is not a gate task.
  - [x] Indented check is not a gate task.
- [x]No trailing space is not a gate task.
EOF
  write_intent "$target" "025-closed-tasks" "draft"
  write_spec "$target/on-track/tracks/025-closed-tasks/spec.md" approved
  write_tasks "$target/on-track/tracks/025-closed-tasks/tasks.md" approved x
  write_intent "$target" "026-malformed-spec" "draft"
  write_tasks "$target/on-track/tracks/026-malformed-spec/tasks.md" approved x
  for malformed in \
    $'---\nstatus: approved\n' \
    $'---\nstatus: approved\nstatus: approved\n---\n' \
    $'---\nstatus: approved\ninvalid field\n---\n' \
    $'status: approved\n' \
    $'---\n---\n'; do
    printf '%s' "$malformed" >"$target/on-track/tracks/026-malformed-spec/spec.md"
    "$index_script" "$target" >/dev/null
    assert_contains "$target/on-track/INDEX.md" "| 026-malformed-spec | draft | spec |"
  done
  write_intent "$target" "027-shipped" "shipped"
  write_spec "$target/on-track/tracks/027-shipped/spec.md" approved
  write_tasks "$target/on-track/tracks/027-shipped/tasks.md" approved x
  write_intent "$target" "028-dropped" "dropped"
  write_intent "$target" "029-directories" "draft"
  mkdir "$target/on-track/tracks/029-directories/spec.md" "$target/on-track/tracks/029-directories/tasks.md"
  write_intent "$target" "030-no-task-lines" "draft"
  write_spec "$target/on-track/tracks/030-no-task-lines/spec.md" approved
  printf '%s\n' '---' 'status: approved' '---' >"$target/on-track/tracks/030-no-task-lines/tasks.md"

  inline_hash="$(printf 'inline fixture\n' | shasum -a 256 | awk '{print $1}')"
  cat >"$target/on-track/refs/inline-source.md" <<EOF
---
type: inline
captured: 2026-09-20
owner: maintainer
sha256: $inline_hash
content_license: MIT
---

# Ref: inline source

## Source content

inline fixture
EOF
  inline_no_separator_hash="$(printf 'inline without separator\n' | shasum -a 256 | awk '{print $1}')"
  cat >"$target/on-track/refs/inline-no-separator.md" <<EOF
---
type: inline
captured: 2026-09-20
owner: maintainer
sha256: $inline_no_separator_hash
content_license: MIT
---

# Ref: inline without separator

## Source content
inline without separator
EOF
  cat >"$target/on-track/refs/pinned-source.md" <<'EOF'
---
type: pointer
source: https://example.com/pinned-source
captured: 2026-09-20
owner: maintainer
pin: fixture-v1
sha256: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
content_license: MIT
---

# Ref: pinned source
EOF
  cat >"$target/on-track/refs/mutable-source.md" <<'EOF'
---
type: pointer
source: https://example.com/mutable-source
captured: 2026-09-20
owner: maintainer
retrieved_at: 2026-09-20T12:00:00Z
sha256: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
content_license: unknown
---

# Ref: mutable source
EOF
  cat >"$target/on-track/research/example-research.md" <<'EOF'
---
captured: 2026-09-20
owner: maintainer
---

# Research: example

## Question
What does the fixture prove?

## Conclusion
It proves multi-source, status-free research is indexed.

## Findings
- The [first source](https://example.com/one) and [second source](https://example.com/two) agree.

## Conflicts
None found.

## Limitations
Fixture evidence only.

## Sources
- [First](https://example.com/one), retrieved 2026-09-20.
- [Second](https://example.com/two), retrieved 2026-09-20.
EOF
  cat >"$target/on-track/assessments/2026-09-20-example-assessment.md" <<'EOF'
---
captured: 2026-09-20
owner: maintainer
scope: fixture
evaluator: fixture/model
tracks: []
---

# Assessment: example

## Conclusion
The fixture conforms.

## Scope and basis
Fixture files only.

## Criteria
- Required schema.

## Findings
- Required fields exist.

## Evidence against conclusion
- None found within the fixture.

## Limitations
- Synthetic fixture.

## Recommendations
- Keep the contract.
EOF
  cat >"$target/on-track/decisions/001-example-decision.md" <<'EOF'
---
id: 001-example-decision
status: accepted
date: 2026-09-20
owner: maintainer
evidence: []
---

# ADR: 001-example-decision

## Context
Fixture context.

## Decision
Keep the fixture.

## Rationale
It verifies the schema.

## Alternatives considered
None.

## Consequences
The decision is indexed.
EOF
  write_handoff "$target/on-track/handoffs/2026-09-20-150000Z-active.md" "2026-09-20T15:00:00Z" "active"
  write_handoff "$target/on-track/handoffs/archive/2026-09-20-140000Z-archived.md" "2026-09-20T14:00:00Z" "archived"

  "$index_script" "$target" >/dev/null
  assert_contains "$target/on-track/INDEX.md" "| track | status | phase |"
  assert_contains "$target/on-track/INDEX.md" "|---|---|---|"
  assert_contains "$target/on-track/INDEX.md" "| 001-example | draft | intent |"
  for phase_track in 020-spec-only 021-tasks-only 022-draft-spec 023-draft-tasks 026-malformed-spec; do
    assert_contains "$target/on-track/INDEX.md" "| $phase_track | draft | spec |"
  done
  assert_contains "$target/on-track/INDEX.md" "| 024-open-tasks | draft | implement 1/2 |"
  assert_contains "$target/on-track/INDEX.md" "| 025-closed-tasks | draft | implement 1/1 |"
  assert_contains "$target/on-track/INDEX.md" "| 027-shipped | shipped | - |"
  assert_contains "$target/on-track/INDEX.md" "| 028-dropped | dropped | - |"
  assert_contains "$target/on-track/INDEX.md" "| 029-directories | draft | intent |"
  assert_contains "$target/on-track/INDEX.md" "| 030-no-task-lines | draft | implement 0/0 |"
  assert_contains "$target/on-track/INDEX.md" "| inline-source | inline | 2026-09-20 |"
  assert_contains "$target/on-track/INDEX.md" "| inline-no-separator | inline | 2026-09-20 |"
  assert_contains "$target/on-track/INDEX.md" "| pinned-source | pointer | 2026-09-20 |"
  assert_contains "$target/on-track/INDEX.md" "| mutable-source | pointer | 2026-09-20 |"
  assert_contains "$target/on-track/INDEX.md" "| example-research | 2026-09-20 |"
  assert_contains "$target/on-track/INDEX.md" "| 2026-09-20-example-assessment | 2026-09-20 |"
  assert_contains "$target/on-track/INDEX.md" "| 001-example-decision | accepted |"
  assert_contains "$target/on-track/INDEX.md" "| 2026-09-20-150000Z-active | 2026-09-20T15:00:00Z |"
  assert_not_contains "$target/on-track/INDEX.md" "2026-09-20-140000Z-archived"
  assert_not_contains "$target/on-track/INDEX.md" "| via |"

  cp "$target/on-track/INDEX.md" "$work/index-first.md"
  "$index_script" "$target" >/dev/null
  cmp "$work/index-first.md" "$target/on-track/INDEX.md" || fail "unchanged index output is not byte-identical"

  cp "$target/on-track/refs/pinned-source.md" "$target/on-track/refs/duplicate-content.md"
  expect_failure "index with duplicate ref hash" "$index_script" "$target"
  assert_contains "$work/failure.err" "duplicates content hash from"
  rm "$target/on-track/refs/duplicate-content.md"

  locator_hash="$(printf '%s' 'https://example.com/mutable-source' | shasum -a 256 | awk '{print $1}')"
  sed -i.bak "s/^sha256: b\\{64\\}$/sha256: $locator_hash/" "$target/on-track/refs/mutable-source.md"
  rm "$target/on-track/refs/mutable-source.md.bak"
  expect_failure "index with locator hash" "$index_script" "$target"
  assert_contains "$work/failure.err" "mutable-source.md sha256 hashes the source locator instead of observed content"
  sed -i.bak "s/^sha256: $locator_hash$/sha256: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb/" "$target/on-track/refs/mutable-source.md"
  rm "$target/on-track/refs/mutable-source.md.bak"

  sed -i.bak 's/^status: draft$/status: unknown/' "$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with invalid track status" "$index_script" "$target"
  assert_contains "$work/failure.err" "001-example invalid status: unknown"
  mv "$target/on-track/tracks/001-example/intent.md.bak" "$target/on-track/tracks/001-example/intent.md"

  cp "$target/on-track/INDEX.md" "$work/index-before-active.md"
  sed -i.bak 's/^status: draft$/status: active/' "$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with active track status" "$index_script" "$target"
  assert_contains "$work/failure.err" "001-example invalid status: active"
  cmp "$work/index-before-active.md" "$target/on-track/INDEX.md" || fail "active status changed INDEX.md"
  mv "$target/on-track/tracks/001-example/intent.md.bak" "$target/on-track/tracks/001-example/intent.md"

  sed -i.bak '/^captured:/d' "$target/on-track/research/example-research.md"
  expect_failure "index with invalid research" "$index_script" "$target"
  assert_contains "$work/failure.err" "example-research.md missing captured field"
  mv "$target/on-track/research/example-research.md.bak" "$target/on-track/research/example-research.md"

  sed -i.bak '/^evaluator:/d' "$target/on-track/assessments/2026-09-20-example-assessment.md"
  expect_failure "index with invalid assessment" "$index_script" "$target"
  assert_contains "$work/failure.err" "2026-09-20-example-assessment.md missing evaluator field"
  mv "$target/on-track/assessments/2026-09-20-example-assessment.md.bak" "$target/on-track/assessments/2026-09-20-example-assessment.md"

  sed -i.bak 's/^status: accepted$/status: proposed/' "$target/on-track/decisions/001-example-decision.md"
  expect_failure "index with invalid decision" "$index_script" "$target"
  assert_contains "$work/failure.err" "001-example-decision.md invalid status: proposed"
  mv "$target/on-track/decisions/001-example-decision.md.bak" "$target/on-track/decisions/001-example-decision.md"

  mv "$target/on-track/handoffs/2026-09-20-150000Z-active.md" "$target/on-track/handoffs/bad-handoff.md"
  expect_failure "index with invalid handoff" "$index_script" "$target"
  assert_contains "$work/failure.err" "bad-handoff.md invalid handoff filename"
  mv "$target/on-track/handoffs/bad-handoff.md" "$target/on-track/handoffs/2026-09-20-150000Z-active.md"

  mkdir "$target/on-track/tracks/011-orphan"
  expect_failure "index with orphan track directory" "$index_script" "$target"
  assert_contains "$work/failure.err" "011-orphan missing intent.md"
  rmdir "$target/on-track/tracks/011-orphan"

  sed -i.bak 's/^research: \[\]$/research: [missing-topic]/' "$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with missing research citation" "$index_script" "$target"
  assert_contains "$work/failure.err" "intent.md research references missing missing-topic"
  mv "$target/on-track/tracks/001-example/intent.md.bak" "$target/on-track/tracks/001-example/intent.md"

  sed -i.bak 's/^research: \[\]$/research: missing-topic/' "$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with non-list research citation" "$index_script" "$target"
  assert_contains "$work/failure.err" "research must use [a, b] list form"
  mv "$target/on-track/tracks/001-example/intent.md.bak" "$target/on-track/tracks/001-example/intent.md"

  cp "$target/on-track/tracks/001-example/intent.md" "$work/intent-original.md"
  awk '{ if ($0 == "status: draft") { print "status: superseded"; print "superseded_by: 099-nowhere"; next } print }' "$work/intent-original.md" >"$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with missing intent replacement" "$index_script" "$target"
  assert_contains "$work/failure.err" "intent.md superseded_by references missing 099-nowhere"
  cp "$work/intent-original.md" "$target/on-track/tracks/001-example/intent.md"

  awk '{ if ($0 == "status: draft") { print; print "superseded_by: 001-example"; next } print }' "$work/intent-original.md" >"$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with self-replaced intent" "$index_script" "$target"
  assert_contains "$work/failure.err" "intent.md superseded_by has a self-reference"
  cp "$work/intent-original.md" "$target/on-track/tracks/001-example/intent.md"

  printf '# not an intent\n' >"$target/on-track/tracks/003-ghost.md"
  awk '{ if ($0 == "status: draft") { print "status: superseded"; print "superseded_by: 003-ghost"; next } print }' "$work/intent-original.md" >"$target/on-track/tracks/001-example/intent.md"
  expect_failure "index with loose track file as intent replacement" "$index_script" "$target"
  assert_contains "$work/failure.err" "intent.md superseded_by references missing 003-ghost"
  rm "$target/on-track/tracks/003-ghost.md"
  cp "$work/intent-original.md" "$target/on-track/tracks/001-example/intent.md"

  write_intent "$target" "002-replacement" "draft"
  awk '{ if ($0 == "status: draft") { print "status: superseded"; print "superseded_by: 002-replacement"; next } print }' "$work/intent-original.md" >"$target/on-track/tracks/001-example/intent.md"
  "$index_script" "$target" >/dev/null
  assert_contains "$target/on-track/INDEX.md" "| 001-example | superseded | - |"
  assert_contains "$target/on-track/INDEX.md" "| 002-replacement | draft | intent |"
  cp "$work/intent-original.md" "$target/on-track/tracks/001-example/intent.md"
  rm -rf "$target/on-track/tracks/002-replacement"

  sed -i.bak 's/^status: accepted$/status: superseded\
superseded_by: 099-nowhere/' "$target/on-track/decisions/001-example-decision.md"
  expect_failure "index with missing decision replacement" "$index_script" "$target"
  assert_contains "$work/failure.err" "001-example-decision.md superseded_by references missing 099-nowhere"
  mv "$target/on-track/decisions/001-example-decision.md.bak" "$target/on-track/decisions/001-example-decision.md"

  sed -i.bak 's/^status: accepted$/status: superseded\
superseded_by: 001-example-decision/' "$target/on-track/decisions/001-example-decision.md"
  expect_failure "index with self-replaced decision" "$index_script" "$target"
  assert_contains "$work/failure.err" "001-example-decision.md superseded_by has a self-reference"
  mv "$target/on-track/decisions/001-example-decision.md.bak" "$target/on-track/decisions/001-example-decision.md"
  mv "$target/on-track/handoffs/2026-09-20-150000Z-active.md" "$target/on-track/handoffs/archive/"
  write_handoff "$target/on-track/handoffs/2026-09-21-080000Z-a.md" "2026-09-21T08:00:00Z" "utc-a"
  write_handoff "$target/on-track/handoffs/2026-09-21-093000Z-b.md" "2026-09-21T09:30:00Z" "utc-b"
  write_handoff "$target/on-track/handoffs/2026-09-21-100000Z-valid.md" "2026-09-21T10:00:00Z" "new-format"
  "$index_script" "$target" >/dev/null
  a_row="$(grep -nF '| 2026-09-21-080000Z-a |' "$target/on-track/INDEX.md" | cut -d: -f1)"
  b_row="$(grep -nF '| 2026-09-21-093000Z-b |' "$target/on-track/INDEX.md" | cut -d: -f1)"
  [ "$a_row" -lt "$b_row" ] || fail "handoff rows are not ordered by captured instant"
  assert_contains "$target/on-track/INDEX.md" "| 2026-09-21-100000Z-valid | 2026-09-21T10:00:00Z |"
  write_handoff "$target/on-track/handoffs/2026-09-22-100000Z-mismatch.md" "2026-09-22T10:00:01Z" "mismatch"
  expect_failure "index with mismatched new handoff timestamp" "$index_script" "$target"
  assert_contains "$work/failure.err" "filename timestamp does not match captured"
  rm "$target/on-track/handoffs/2026-09-22-100000Z-mismatch.md"
  write_handoff "$target/on-track/handoffs/2026-09-22-100000Z-fourth.md" "2026-09-22T10:00:00Z" "fourth"
  expect_failure "index with four active handoffs" "$index_script" "$target"
  assert_contains "$work/failure.err" "more than three handoffs are active"
  rm "$target/on-track/handoffs/2026-09-22-100000Z-fourth.md"

  # A handoff with ## Next actions is accepted.
  rm "$target/on-track/handoffs/2026-09-21-100000Z-valid.md"
  write_handoff "$target/on-track/handoffs/2026-09-21-100000Z-nextactions.md" "2026-09-21T10:00:00Z" "next-actions"
  "$index_script" "$target" >/dev/null
  assert_contains "$target/on-track/INDEX.md" "| 2026-09-21-100000Z-nextactions | 2026-09-21T10:00:00Z |"

  # A handoff without ## Next actions is rejected and leaves INDEX.md unchanged.
  cp "$target/on-track/INDEX.md" "$work/index-before-noactions.md"
  write_handoff_no_actions "$target/on-track/handoffs/2026-09-21-100000Z-nextactions.md" "2026-09-21T10:00:00Z" "next-actions"
  expect_failure "index with handoff missing next actions" "$index_script" "$target"
  assert_contains "$work/failure.err" "missing heading ## Next actions"
  cmp "$work/index-before-noactions.md" "$target/on-track/INDEX.md" || fail "rejected handoff changed INDEX.md"
  write_handoff "$target/on-track/handoffs/2026-09-21-100000Z-nextactions.md" "2026-09-21T10:00:00Z" "next-actions"

  rm "$target/on-track/handoffs/2026-09-21-080000Z-a.md" "$target/on-track/handoffs/2026-09-21-093000Z-b.md"
  "$index_script" "$target" >/dev/null
  cp "$target/on-track/INDEX.md" "$work/index-before-retired-handoff.md"

  # Offset names, minute-precision names, offset timestamps, and P0/P1 headings are rejected.
  retired="$target/on-track/handoffs/2026-09-21-1000-+0200-offset.md"
  write_handoff "$retired" "2026-09-21T10:00:00+02:00" "offset"
  expect_failure "index with offset handoff name" "$index_script" "$target"
  assert_contains "$work/failure.err" "2026-09-21-1000-+0200-offset.md invalid handoff filename"
  assert_contains "$work/failure.err" "2026-09-21-1000-+0200-offset.md invalid captured timestamp"
  cmp "$work/index-before-retired-handoff.md" "$target/on-track/INDEX.md" || fail "offset handoff name changed INDEX.md"
  rm "$retired"

  retired="$target/on-track/handoffs/2026-09-21-1000-Z-minute.md"
  write_handoff "$retired" "2026-09-21T10:00:00Z" "minute"
  expect_failure "index with minute-precision handoff name" "$index_script" "$target"
  assert_contains "$work/failure.err" "2026-09-21-1000-Z-minute.md invalid handoff filename"
  cmp "$work/index-before-retired-handoff.md" "$target/on-track/INDEX.md" || fail "minute-precision handoff name changed INDEX.md"
  rm "$retired"

  retired="$target/on-track/handoffs/2026-09-21-080000Z-offcap.md"
  write_handoff "$retired" "2026-09-21T10:00:00+02:00" "offcap"
  expect_failure "index with offset captured timestamp" "$index_script" "$target"
  assert_contains "$work/failure.err" "2026-09-21-080000Z-offcap.md invalid captured timestamp"
  cmp "$work/index-before-retired-handoff.md" "$target/on-track/INDEX.md" || fail "offset captured changed INDEX.md"
  rm "$retired"

  retired="$target/on-track/handoffs/2026-09-21-090000Z-priority.md"
  write_handoff "$retired" "2026-09-21T09:00:00Z" "priority"
  sed -i.bak 's/^## Next actions$/## P0 next actions/' "$retired"
  rm "$retired.bak"
  printf '\n## P1 next actions\n- Fixture.\n\n## First next action\nRun it.\n' >>"$retired"
  expect_failure "index with P0/P1 handoff headings" "$index_script" "$target"
  assert_contains "$work/failure.err" "2026-09-21-090000Z-priority.md missing heading ## Next actions"
  cmp "$work/index-before-retired-handoff.md" "$target/on-track/INDEX.md" || fail "P0/P1 handoff changed INDEX.md"
  rm "$retired"

  "$index_script" "$target" >/dev/null
  cp "$target/on-track/INDEX.md" "$work/index-before-invalid.md"
  cat >"$target/on-track/research/invalid-research.md" <<'EOF'
---
owner: maintainer
---
EOF
  expect_failure "index does not publish invalid output" "$index_script" "$target"
  assert_contains "$work/failure.err" "INDEX not updated:"
  cmp "$work/index-before-invalid.md" "$target/on-track/INDEX.md" || fail "invalid index changed INDEX.md"
  for temp_index in "$target/on-track"/.INDEX.md.*; do
    [ ! -e "$temp_index" ] || fail "temporary index was not cleaned up"
  done
  rm "$target/on-track/research/invalid-research.md"

  "$index_script" "$target" >/dev/null
  pass "index"
}

run_approval() {
  missing_intent="$work/gate-missing-intent"
  mkdir -p "$missing_intent/on-track/tracks/001-example"
  write_spec "$missing_intent/on-track/tracks/001-example/spec.md" "approved"
  write_tasks "$missing_intent/on-track/tracks/001-example/tasks.md" "approved" "x"
  expect_failure "gate without intent.md" "$gate" --track 001-example --root "$missing_intent"

  short="$work/gate-short"
  write_intent "$short" "001-example" "draft"
  write_spec "$short/on-track/tracks/001-example/spec.md" "draft"
  write_tasks "$short/on-track/tracks/001-example/tasks.md" "approved" "x"
  expect_failure "gate with unapproved spec" "$gate" --track 001-example --root "$short"

  write_spec "$short/on-track/tracks/001-example/spec.md" "approved"
  write_tasks "$short/on-track/tracks/001-example/tasks.md" "draft" "x"
  expect_failure "gate with unapproved tasks" "$gate" --track 001-example --root "$short"

  write_tasks "$short/on-track/tracks/001-example/tasks.md" "approved" " "
  expect_failure "gate with open task" "$gate" --track 001-example --root "$short"

  write_spec "$short/on-track/tracks/001-example/spec.md" "draft"
  write_tasks "$short/on-track/tracks/001-example/tasks.md" "draft" " "
  structure_output="$("$gate" --mode structure --track 001-example --root "$short")"
  [ "$structure_output" = "PASS: 001-example structure valid" ] || fail "structure mode did not accept a draft with open tasks"
  expect_failure "gate with unknown mode" "$gate" --mode draft --track 001-example --root "$short"
  assert_contains "$work/failure.out" "structure and completion"

  write_spec "$short/on-track/tracks/001-example/spec.md" "approved"
  write_tasks "$short/on-track/tracks/001-example/tasks.md" "approved" "x"
  "$gate" --track 001-example --root "$short" >/dev/null

  write_plan "$short/on-track/tracks/001-example/plan.md" "approved"
  expect_failure "gate with root plan.md" "$gate" --track 001-example --root "$short"
  assert_contains "$work/failure.out" "loose files outside assets/: plan.md"
  rm "$short/on-track/tracks/001-example/plan.md"

  printf '# Decisions\n' >"$short/on-track/tracks/001-example/decisions.md"
  expect_failure "gate with root decisions.md" "$gate" --track 001-example --root "$short"
  assert_contains "$work/failure.out" "loose files outside assets/: decisions.md"
  rm "$short/on-track/tracks/001-example/decisions.md"

  mkdir "$short/on-track/tracks/001-example/spec"
  expect_failure "gate with spec directory" "$gate" --track 001-example --root "$short"
  assert_contains "$work/failure.out" "loose files outside assets/: spec"
  rmdir "$short/on-track/tracks/001-example/spec"

  cat >"$short/on-track/tracks/001-example/tasks.md" <<'EOF'
---
status: approved
---

# Tasks

- [x] T001 Fixture. Files: fixture. Validate: true
EOF
  expect_failure "gate with ungrouped tasks" "$gate" --track 001-example --root "$short"
  assert_contains "$work/failure.out" "tasks.md has no group header"
  pass "approval gate"
}

assert_installed_layout() {
  agents_dir="$1"
  claude_dir="$2"
  commands_dir="$3"
  count=0
  for skill in "$repo_root"/skills/ot-*; do
    name="$(basename "$skill")"
    [ -d "$agents_dir/$name" ] || fail "agent skill does not resolve: $agents_dir/$name"
    [ -d "$claude_dir/$name" ] || fail "Claude mirror does not resolve: $claude_dir/$name"
    count=$((count + 1))
  done
  [ "$count" -eq 7 ] || fail "expected 7 installed skills, got $count"
  [ ! -e "$agents_dir/shared" ] || fail "shared link was installed"
  [ ! -e "$claude_dir/shared" ] || fail "shared Claude mirror was installed"
  cmd_count=0
  for cmd in "$repo_root"/commands/ot-*.md; do
    name="$(basename "$cmd")"
    [ -e "$commands_dir/$name" ] || fail "command does not resolve: $commands_dir/$name"
    cmd_count=$((cmd_count + 1))
  done
  [ "$cmd_count" -eq 7 ] || fail "expected 7 installed commands, got $cmd_count"
}

# tree_fingerprint <dir>: sha256 over every file path and content.
tree_fingerprint() {
  (cd "$1" && find . -type f -exec shasum -a 256 {} + | LC_ALL=C sort -k2 | shasum -a 256)
}

# check_installed_resources <agents-skills-dir> <claude-skills-dir>
# Reads every skill's metadata and owner templates and resolves sibling
# resources from the installed directories. Prints the first broken location
# and returns 1.
check_installed_resources() {
  local dir skill name rel count
  for dir in "$1" "$2"; do
    count=0
    for skill in "$dir"/ot-*; do
      [ -d "$skill" ] || continue
      name="$(basename "$skill")"
      [ -r "$skill/SKILL.md" ] || { echo "installed skill metadata is unreadable: $skill/SKILL.md"; return 1; }
      [ "$(frontmatter_field "$skill/SKILL.md" name)" = "$name" ] || { echo "installed skill metadata name does not match $name: $skill/SKILL.md"; return 1; }
      [ -n "$(frontmatter_field "$skill/SKILL.md" description)" ] || { echo "installed skill metadata has no description: $skill/SKILL.md"; return 1; }
      for rel in "$skill"/assets/*; do
        [ -e "$rel" ] || continue
        [ -s "$rel" ] || { echo "installed template is empty or unreadable: $rel"; return 1; }
      done
      for rel in $(grep -oE '(^|[^.A-Za-z])\./(scripts|assets)/[A-Za-z0-9_-]+\.(sh|md)' "$skill/SKILL.md" | grep -oE '\./(scripts|assets)/[A-Za-z0-9_-]+\.(sh|md)' | sort -u); do
        [ -f "$skill/$rel" ] || { echo "installed owner resource does not resolve: $skill/$rel"; return 1; }
        case "$rel" in *.sh) [ -x "$skill/$rel" ] || { echo "installed owner script is not executable: $skill/$rel"; return 1; };; esac
      done
      for rel in $(grep -oE '\.\./ot-[a-z]+/(scripts|assets)/[A-Za-z0-9_-]+\.(sh|md)' "$skill/SKILL.md" | sort -u); do
        [ -f "$skill/$rel" ] || { echo "installed sibling resource does not resolve: $skill/$rel"; return 1; }
        case "$rel" in *.sh) [ -x "$skill/$rel" ] || { echo "installed sibling script is not executable: $skill/$rel"; return 1; };; esac
      done
      count=$((count + 1))
    done
    [ "$count" -eq 7 ] || { echo "expected 7 installed skills in $dir, got $count"; return 1; }
  done
}

# run_installed_scripts <label> <skills-dir>: init twice, index, and gate through
# the installed owner scripts against a disposable target.
run_installed_scripts() {
  local t="$work/installed-run-$1" base="$2" track first
  local i_init="$2/ot-init/scripts/on-track-init.sh"
  local i_index="$2/ot-init/scripts/on-track-index.sh"
  local i_gate="$2/ot-spec/scripts/on-track-gate.sh"
  rm -rf "$t"
  mkdir -p "$t"
  "$i_init" "$t" >/dev/null || fail "installed init failed through $base"
  first="$(tree_fingerprint "$t")"
  "$i_init" "$t" >/dev/null || fail "installed init rerun failed through $base"
  [ "$first" = "$(tree_fingerprint "$t")" ] || fail "installed init rerun changed the target through $base"
  for track in research refs handoffs/archive assessments decisions tracks; do
    assert_dir "$t/on-track/$track"
  done
  assert_file "$t/on-track/INDEX.md"
  assert_file "$t/AGENTS.md"

  write_intent "$t" 001-valid draft
  write_spec "$t/on-track/tracks/001-valid/spec.md" approved
  write_tasks "$t/on-track/tracks/001-valid/tasks.md" approved x
  write_intent "$t" 002-open draft
  write_spec "$t/on-track/tracks/002-open/spec.md" approved
  write_tasks "$t/on-track/tracks/002-open/tasks.md" approved " "
  write_intent "$t" 003-unapproved draft
  write_spec "$t/on-track/tracks/003-unapproved/spec.md" draft
  write_tasks "$t/on-track/tracks/003-unapproved/tasks.md" approved x

  "$i_index" "$t" >/dev/null || fail "installed index failed through $base"
  assert_contains "$t/on-track/INDEX.md" "| 001-valid | draft | implement 1/1 |"
  assert_contains "$t/on-track/INDEX.md" "| 002-open | draft | implement 0/1 |"
  assert_contains "$t/on-track/INDEX.md" "| 003-unapproved | draft | spec |"
  cp "$t/on-track/INDEX.md" "$t/index.first"
  "$i_index" "$t" >/dev/null || fail "installed index rerun failed through $base"
  cmp -s "$t/index.first" "$t/on-track/INDEX.md" || fail "installed index rerun changed INDEX.md through $base"

  [ "$("$i_gate" --track 001-valid --root "$t")" = "PASS: 001-valid cycle intact" ] || fail "installed gate did not accept the valid closed track through $base"
  expect_failure "installed gate with an open task through $base" "$i_gate" --track 002-open --root "$t"
  assert_contains "$work/failure.out" "open task"
  expect_failure "installed gate with an unapproved spec through $base" "$i_gate" --track 003-unapproved --root "$t"
  assert_contains "$work/failure.out" "spec.md status must be approved"
}

# verify_installed_layout <label> <agents-skills-dir> <claude-skills-dir>
verify_installed_layout() {
  local msg
  msg="$(check_installed_resources "$2" "$3")" || fail "$msg"
  run_installed_scripts "$1-agents" "$2"
  run_installed_scripts "$1-claude" "$3"
}

run_install() {
  custom="$work/install-custom"
  mkdir -p "$custom/claude"
  "$repo_root/install.sh" --agents-dir "$custom/agents/skills" --claude-dir "$custom/claude/skills" >/dev/null
  assert_installed_layout "$custom/agents/skills" "$custom/claude/skills" "$custom/claude/commands"
  verify_installed_layout custom "$custom/agents/skills" "$custom/claude/skills"

  default="$work/install-default"
  mkdir -p "$default/home/.claude"
  HOME="$default/home" "$repo_root/install.sh" >/dev/null
  assert_installed_layout "$default/home/.agents/skills" "$default/home/.claude/skills" "$default/home/.claude/commands"
  verify_installed_layout default "$default/home/.agents/skills" "$default/home/.claude/skills"

  # A broken sibling in a disposable copy of the package fails at the affected location.
  broken="$work/install-broken"
  mkdir -p "$broken/pkg" "$broken/claude"
  for item in skills commands install.sh; do
    cp -R "$repo_root/$item" "$broken/pkg/$item"
  done
  rm "$broken/pkg/skills/ot-spec/scripts/on-track-gate.sh"
  "$broken/pkg/install.sh" --agents-dir "$broken/agents/skills" --claude-dir "$broken/claude/skills" >/dev/null
  if broken_message="$(check_installed_resources "$broken/agents/skills" "$broken/claude/skills")"; then
    fail "installation validation passed with a broken installed sibling"
  fi
  case "$broken_message" in
    *ot-spec/scripts/on-track-gate.sh*) ;;
    *) fail "broken sibling was not reported at its location: $broken_message";;
  esac
  pass "install"
}

run_readme_checks() {
  local english="$repo_root/README.md" portuguese="$repo_root/README.pt-BR.md" page language diagram english_headings portuguese_headings
  assert_file "$english"
  assert_file "$portuguese"
  assert_contains "$english" '](README.pt-BR.md)'
  assert_contains "$portuguese" '](README.md)'
  english_headings="$(awk '/^## / { count++ } END { print count + 0 }' "$english")"
  portuguese_headings="$(awk '/^## / { count++ } END { print count + 0 }' "$portuguese")"
  [ "$english_headings" -eq "$portuguese_headings" ] || fail "README second-level heading counts differ"
  for language in en pt; do
    case "$language" in
      en) page="$english" ;;
      pt) page="$portuguese" ;;
    esac
    for diagram in lanes workflow support-context; do
      assert_contains "$page" "](docs/images/$language/$diagram.png)"
    done
    if grep -Ein 'normaliz|spec/|plan[.]md|openspec|(^|[^[:alpha:]])ft-(init|intent|spec|implement|research|assess|handoff)([^[:alnum:]_]|$)|(^|[^[:alpha:]])ft-\*|—' "$page"; then
      fail "$page contains retired README wording or an em dash"
    fi
  done
}

run_resources() {
  run_readme_checks
  legacy_files="$(cd "$repo_root" && grep -rl 'fast-track-ai' skills commands install.sh AGENTS.md | LC_ALL=C sort)"
  expected_legacy_files="$(printf '%s\n' 'skills/ot-init/SKILL.md' 'skills/ot-init/scripts/on-track-init.sh')"
  [ "$legacy_files" = "$expected_legacy_files" ] || fail "unexpected legacy-name files: $legacy_files"
  # A preceding letter excludes unrelated words such as draft-status.
  old_command_pattern='(^|[^[:alpha:]])ft-(init|intent|spec|implement|research|assess|handoff)([^[:alnum:]_]|$)|(^|[^[:alpha:]])ft-\*'
  if grep -rEn "$old_command_pattern" "$repo_root/skills" "$repo_root/commands" "$repo_root/install.sh" "$repo_root/AGENTS.md" "$repo_root/README.md" "$repo_root/README.pt-BR.md"; then
    fail "old command name remains in the package"
  fi
  skill_count="$(find "$repo_root/skills" -mindepth 1 -maxdepth 1 -type d -name 'ot-*' | wc -l | tr -d ' ')"
  command_count="$(find "$repo_root/commands" -mindepth 1 -maxdepth 1 -type f -name 'ot-*.md' | wc -l | tr -d ' ')"
  [ "$skill_count" -eq 7 ] || fail "expected seven ot-* skill directories, got $skill_count"
  [ "$command_count" -eq 7 ] || fail "expected seven ot-*.md command files, got $command_count"

  init_skill="$repo_root/skills/ot-init/SKILL.md"
  intent_skill="$repo_root/skills/ot-intent/SKILL.md"
  spec_skill="$repo_root/skills/ot-spec/SKILL.md"
  assess_skill="$repo_root/skills/ot-assess/SKILL.md"
  research_skill="$repo_root/skills/ot-research/SKILL.md"
  handoff_skill="$repo_root/skills/ot-handoff/SKILL.md"

  for resource in './scripts/on-track-init.sh' './scripts/on-track-index.sh' './assets/AGENTS-snippet.md'; do
    assert_contains "$init_skill" "$resource"
  done
  for resource in './assets/intent.md' './assets/ref.md'; do
    assert_contains "$intent_skill" "$resource"
  done
  for resource in './assets/spec.md' './assets/tasks.md' './assets/decisions.md' './scripts/on-track-gate.sh'; do
    assert_contains "$spec_skill" "$resource"
  done
  assert_contains "$assess_skill" './assets/assessment.md'
  assert_contains "$research_skill" './assets/research.md'
  assert_contains "$handoff_skill" './assets/handoff.md'

  for resource in './scripts/on-track-init.sh' './scripts/on-track-index.sh' './assets/AGENTS-snippet.md' './assets/intent.md' './assets/ref.md' './assets/spec.md' './assets/tasks.md' './assets/decisions.md' './scripts/on-track-gate.sh' './assets/assessment.md' './assets/research.md' './assets/handoff.md'; do
    owner_count="$(grep -Fl "$resource" "$repo_root"/skills/ot-*/SKILL.md | wc -l | tr -d ' ')"
    [ "$owner_count" -eq 1 ] || fail "$resource has $owner_count owner skill references; expected 1"
  done

  assert_not_file "$repo_root/skills/ot-init/assets/assessment.md"
  assert_not_file "$repo_root/skills/ot-init/assets/refs.md"
  for skill_file in "$repo_root"/skills/ot-*/SKILL.md; do
    assert_not_contains "$skill_file" 'ot-init/assets/assessment.md'
    assert_not_contains "$skill_file" 'ot-init/assets/refs.md'
  done
  for skill_file in "$repo_root"/skills/ot-*/SKILL.md; do
    assert_contains "$skill_file" "resolve from this skill's installed directory, and \`on-track/\` paths resolve from the target repository root"
  done
  pass "resource guidance"
}

run_workflows() {
  intent_skill="$repo_root/skills/ot-intent/SKILL.md"
  assert_contains "$intent_skill" 'reading the relevant files does not settle'
  assert_contains "$intent_skill" 'behavior measured'
  assert_contains "$intent_skill" 'evidence weighed across several subsystems'
  assert_contains "$intent_skill" 'material counterevidence'
  assert_contains "$intent_skill" 'reading files or running one command do not justify an assessment'

  assess_skill="$repo_root/skills/ot-assess/SKILL.md"
  research_skill="$repo_root/skills/ot-research/SKILL.md"
  handoff_skill="$repo_root/skills/ot-handoff/SKILL.md"
  assess_template="$repo_root/skills/ot-assess/assets/assessment.md"
  research_template="$repo_root/skills/ot-research/assets/research.md"
  handoff_template="$repo_root/skills/ot-handoff/assets/handoff.md"

  for workflow in assess research handoff; do
    assert_file "$repo_root/commands/ot-$workflow.md"
    assert_file "$repo_root/skills/ot-$workflow/SKILL.md"
    assert_contains "$repo_root/commands/ot-$workflow.md" "\`ot-$workflow\`"
  done

  assert_not_matches "$research_skill" 'base `research`|base research skill|Run the base'
  assert_not_matches "$handoff_skill" 'base `handoff`|base handoff skill|Run the base'
  assert_not_matches "$repo_root/commands/ot-research.md" 'base research skill|Run the base'
  assert_not_matches "$repo_root/commands/ot-handoff.md" 'base handoff skill|Run the base'

  for field_name in captured owner; do
    assert_contains "$research_template" "$field_name:"
  done
  for heading in '## Question' '## Conclusion' '## Conflicts' '## Limitations' '## Sources'; do
    assert_contains "$research_template" "$heading"
  done
  assert_not_matches "$research_template" '^(source|status):'

  for field_name in captured owner scope evaluator tracks; do
    assert_contains "$assess_template" "$field_name:"
  done
  for heading in '## Conclusion' '## Scope and basis' '## Criteria' '## Findings' '## Evidence against conclusion' '## Limitations' '## Recommendations'; do
    assert_contains "$assess_template" "$heading"
  done
  assert_not_matches "$assess_template" '^status:'

  for field_name in captured owner focus; do
    assert_contains "$handoff_template" "$field_name:"
  done
  for heading in '## Objective' '## Active user instructions, verbatim' '## Current state' '## Completed' '## Next actions' '## Unresolved decisions' '## Relevant paths and durable artifacts' '## Observed command results' '## Blockers and risks'; do
    assert_contains "$handoff_template" "$heading"
  done
  assert_not_matches "$handoff_template" '^status:'
  assert_not_matches "$handoff_template" '^## (P0|P1) next actions$|^## First next action$'

  for package_file in "$repo_root"/skills/ot-*/SKILL.md "$repo_root"/commands/ot-*.md; do
    assert_not_matches "$package_file" 'Jhony Walker|jhonywalkeer|Guia Completo sobre Architecture'
  done

  assert_contains "$research_skill" 'the result is inconclusive'
  assert_contains "$research_skill" 'Never overwrite an existing research file silently.'
  assert_contains "$assess_skill" 'the problem, its evidence, its consequence, and the recommendation'
  assert_contains "$assess_skill" 'any priority follows from the stated consequence'
  assert_contains "$assess_skill" 'Set `tracks` to the IDs of the tracks the assessment evaluates, or `[]`'
  assert_contains "$assess_skill" 'Never overwrite an existing assessment file silently.'
  assert_contains "$assess_template" 'the problem, its evidence citation, its consequence, and the recommendation'
  pass "self-contained artifact workflows"
}

run_refs() {
  template="$repo_root/skills/ot-intent/assets/ref.md"
  intent_skill="$repo_root/skills/ot-intent/SKILL.md"
  intent_template="$repo_root/skills/ot-intent/assets/intent.md"
  assert_file "$template"
  for contract_text in 'content_license' 'Normalize it to UTF-8' 'observed at capture time' 'never the URL' 'Use `pin` when' 'retrieved_at'; do
    assert_contains "$intent_skill" "$contract_text"
  done
  assert_not_contains "$template" '## Contract'
  assert_contains "$intent_skill" 'compare the hash with existing refs'
  assert_contains "$intent_skill" 'create no ref or synthetic hash'
  assert_contains "$intent_skill" 'Open questions'
  assert_contains "$intent_skill" 'Assumed state'
  for provenance_list in '### Stated by the user' '### Verified by the agent' '### Unverified assumptions' '### Access limits'; do
    assert_contains "$intent_template" "$provenance_list"
  done


  unavailable="$work/unavailable-ref"
  "$init_script" "$unavailable" >/dev/null
  write_intent "$unavailable" "001-unavailable-source" "draft"
  cat >>"$unavailable/on-track/tracks/001-unavailable-source/intent.md" <<'EOF'

# Intent: unavailable source

## Assumed state
The source payload was not available.

## Open questions
- Maintainer: provide the source URL, file, or text.
EOF
  assert_not_file "$unavailable/on-track/refs/unavailable-source.md"
  "$index_script" "$unavailable" >/dev/null
  existing="$unavailable/on-track/refs/existing-source.md"
  candidate_payload='captured source payload'
  candidate_hash="$(printf '%s' "$candidate_payload" | shasum -a 256 | awk '{print $1}')"
  cat >"$existing" <<EOF
---
type: pointer
source: https://example.com/existing-source
captured: 2026-09-20
owner: maintainer
pin: fixture-v1
sha256: $candidate_hash
content_license: MIT
---

# Ref: existing source
EOF
  existing_slug="$(basename "$existing" .md)"
  [ "$candidate_hash" = "$(frontmatter_field "$existing" sha256)" ] || fail "candidate hash did not match existing ref"
  assert_contains "$intent_skill" 'reuses the existing slug'
  assert_not_file "$unavailable/on-track/refs/duplicate-source.md"
  "$index_script" "$unavailable" >/dev/null
  assert_contains "$unavailable/on-track/INDEX.md" "| $existing_slug | pointer | 2026-09-20 |"
  pass "ref capture contract"
}

run_decisions() {
  intent_skill="$repo_root/skills/ot-intent/SKILL.md"
  spec_skill="$repo_root/skills/ot-spec/SKILL.md"
  implement_skill="$repo_root/skills/ot-implement/SKILL.md"
  template="$repo_root/skills/ot-spec/assets/decisions.md"

  for decision_skill in "$intent_skill" "$spec_skill" "$implement_skill" "$repo_root/skills/ot-init/assets/AGENTS-snippet.md"; do
    for contract_text in 'only when BOTH hold' 'at least one alternative weighed and rejected for a stated reason' 'reversing it takes more than reverting a diff' 'a future reader would likely undo it without the recorded reason' 'Durability alone' 'a restated user preference or instruction' 'local, easily reversible, or obvious choices do not qualify' 'A user preference with no weighed alternative is a constraint in the intent'; do
      assert_contains "$decision_skill" "$contract_text"
    done
  done
  adr_contract="$(sed -n 's/.*\(A decision qualifies only when BOTH hold:.*not an ADR\.\).*/\1/p' "$intent_skill")"
  [ -n "$adr_contract" ] || fail "missing ADR qualification text"
  for decision_skill in "$spec_skill" "$implement_skill" "$repo_root/skills/ot-init/assets/AGENTS-snippet.md"; do
    assert_contains "$decision_skill" "$adr_contract"
  done
  assert_contains "$intent_skill" 'the user makes a decision in the conversation'
  assert_contains "$implement_skill" 'materially changes approved `spec.md` or `tasks.md`'
  assert_contains "$implement_skill" 'renewed explicit approval'
  assert_contains "$implement_skill" 'If it does not materially change approved scope or design, record it and continue.'
  assert_not_matches "$template" '^evidence:'
  assert_contains "$template" '## Evidence'
  assert_contains "$spec_skill" 'the ADR frontmatter has no `evidence` field'
  assert_contains "$spec_skill" 'set the original'"'"'s `status: superseded` and add `superseded_by: <replacement-id>`'
  replacement="$work/replacement-target"
  "$init_script" "$replacement" >/dev/null
  write_intent "$replacement" "001-replacement-fixture" "draft"
  original_payload_hash="$(printf '%s' 'mutable payload v1' | shasum -a 256 | awk '{print $1}')"
  replacement_payload_hash="$(printf '%s' 'mutable payload v2' | shasum -a 256 | awk '{print $1}')"
  cat >"$replacement/on-track/refs/mutable-v1.md" <<EOF
---
type: pointer
source: https://example.com/mutable
captured: 2026-09-20
owner: maintainer
retrieved_at: 2026-09-20T12:00:00Z
sha256: $original_payload_hash
content_license: unknown
---

# Ref: mutable v1
EOF
  cp "$replacement/on-track/refs/mutable-v1.md" "$work/mutable-v1.before"
  cat >"$replacement/on-track/refs/mutable-v2.md" <<EOF
---
type: pointer
source: https://example.com/mutable
captured: 2026-09-20
owner: maintainer
retrieved_at: 2026-09-21T12:00:00Z
sha256: $replacement_payload_hash
content_license: unknown
---

# Ref: mutable v2
EOF
  cat >"$replacement/on-track/decisions/001-original.md" <<'EOF'
---
id: 001-original
status: superseded
date: 2026-09-20
owner: maintainer
superseded_by: 002-replacement
evidence: []
---

# ADR: 001-original

## Context
Original fixture decision.

## Decision
Use the original fixture path.

## Rationale
It was the accepted initial choice.

## Alternatives considered
Use the replacement path immediately.

## Consequences
The original decision remains historical.
EOF
  cp "$replacement/on-track/decisions/001-original.md" "$work/001-original.before"
  cat >"$replacement/on-track/decisions/002-replacement.md" <<'EOF'
---
id: 002-replacement
status: accepted
date: 2026-09-21
owner: maintainer
evidence: []
---

# ADR: 002-replacement

## Context
The original fixture decision no longer applies.

## Decision
Use the replacement fixture path.

## Rationale
The observed mutable source changed.

## Alternatives considered
Keep the original path.

## Consequences
New work follows the replacement decision.
EOF
  "$index_script" "$replacement" >/dev/null
  cmp "$work/mutable-v1.before" "$replacement/on-track/refs/mutable-v1.md" || fail "mutable original ref changed"
  cmp "$work/001-original.before" "$replacement/on-track/decisions/001-original.md" || fail "original ADR content changed"
  assert_contains "$replacement/on-track/INDEX.md" "| mutable-v1 | pointer | 2026-09-20 |"
  assert_contains "$replacement/on-track/INDEX.md" "| mutable-v2 | pointer | 2026-09-20 |"
  assert_contains "$replacement/on-track/INDEX.md" "| 001-original | superseded |"
  assert_contains "$replacement/on-track/INDEX.md" "| 002-replacement | accepted |"
  assert_contains "$replacement/on-track/decisions/001-original.md" "superseded_by: 002-replacement"
  pass "decision capture contract"
}

run_handoff() {
  target="$work/handoff-target"
  "$init_script" "$target" >/dev/null
  write_handoff "$target/on-track/handoffs/2026-09-20-080000Z-first.md" "2026-09-20T08:00:00Z" "first"
  write_handoff "$target/on-track/handoffs/2026-09-20-090000Z-second.md" "2026-09-20T09:00:00Z" "second"
  write_handoff "$target/on-track/handoffs/2026-09-20-100000Z-third.md" "2026-09-20T10:00:00Z" "third"
  write_handoff "$target/on-track/handoffs/2026-09-20-110000Z-fourth.md" "2026-09-20T11:00:00Z" "fourth"
  mv "$target/on-track/handoffs/2026-09-20-080000Z-first.md" "$target/on-track/handoffs/archive/"

  active_handoffs=("$target"/on-track/handoffs/*.md)
  [ "${#active_handoffs[@]}" -eq 3 ] || fail "handoff fixture did not retain exactly three active files"
  assert_file "$target/on-track/handoffs/archive/2026-09-20-080000Z-first.md"
  assert_contains "$target/on-track/handoffs/archive/2026-09-20-080000Z-first.md" '> Preserve this exact instruction.'
  assert_not_matches "$repo_root/skills/ot-handoff/SKILL.md" 'base `handoff`|base handoff skill|Run the base'
  handoff_skill="$repo_root/skills/ot-handoff/SKILL.md"
  collision_line="$(grep -n 'Before writing, check that this path exists in neither' "$handoff_skill" | cut -d: -f1)"
  write_line="$(grep -n 'Write the final document directly to that path' "$handoff_skill" | cut -d: -f1)"
  validate_line="$(grep -n 'Validate the new handoff before touching any other handoff' "$handoff_skill" | cut -d: -f1)"
  archive_line="$(grep -n 'Move each older handoff to `on-track/handoffs/archive/`' "$handoff_skill" | cut -d: -f1)"
  index_line="$(grep -n 'run `../ot-init/scripts/on-track-index.sh' "$handoff_skill" | cut -d: -f1)"
  [ -n "$collision_line" ] && [ -n "$write_line" ] && [ -n "$validate_line" ] && [ -n "$archive_line" ] && [ -n "$index_line" ] || fail "handoff skill lacks a collision, write, validate, archive, or index step"
  [ "$collision_line" -lt "$write_line" ] && [ "$write_line" -lt "$validate_line" ] || fail "handoff skill does not check collision, then write, then validate"
  [ "$validate_line" -lt "$archive_line" ] && [ "$archive_line" -lt "$index_line" ] || fail "handoff skill does not validate, then archive, then index"
  "$index_script" "$target" >/dev/null
  assert_not_contains "$target/on-track/INDEX.md" '2026-09-20-080000Z-first'
  second_row="$(grep -nF '| 2026-09-20-090000Z-second |' "$target/on-track/INDEX.md" | cut -d: -f1)"
  third_row="$(grep -nF '| 2026-09-20-100000Z-third |' "$target/on-track/INDEX.md" | cut -d: -f1)"
  fourth_row="$(grep -nF '| 2026-09-20-110000Z-fourth |' "$target/on-track/INDEX.md" | cut -d: -f1)"
  [ "$second_row" -lt "$third_row" ] && [ "$third_row" -lt "$fourth_row" ] || fail "handoffs are not ordered by captured instant"

  # A handoff without ## Next actions is rejected without changing INDEX.
  "$index_script" "$target" >/dev/null
  assert_contains "$target/on-track/INDEX.md" "| 2026-09-20-100000Z-third | 2026-09-20T10:00:00Z |"
  cp "$target/on-track/INDEX.md" "$work/handoff-index-before.md"
  write_handoff_no_actions "$target/on-track/handoffs/2026-09-20-100000Z-third.md" "2026-09-20T10:00:00Z" "third-new"
  expect_failure "handoff missing next actions" "$index_script" "$target"
  assert_contains "$work/failure.err" "missing heading ## Next actions"
  cmp "$work/handoff-index-before.md" "$target/on-track/INDEX.md" || fail "rejected handoff changed INDEX.md"
  pass "handoff active window"
}

run_spec() {
  missing="$work/spec-missing"
  write_intent "$missing" "001-example" "draft"
  write_tasks "$missing/on-track/tracks/001-example/tasks.md" "approved" "x"
  expect_failure "gate without spec.md" "$gate" --track 001-example --root "$missing"

  leftover="$work/spec-leftover-dir"
  write_intent "$leftover" "002-example" "draft"
  mkdir -p "$leftover/on-track/tracks/002-example/spec"
  printf '# Spec\n' >"$leftover/on-track/tracks/002-example/spec/spec.md"
  write_tasks "$leftover/on-track/tracks/002-example/spec/tasks.md" "approved" "x"
  expect_failure "gate with spec/ and no root spec.md" "$gate" --track 002-example --root "$leftover"
  assert_contains "$work/failure.out" "loose files outside assets/: spec"

  ok="$work/spec-ok"
  write_intent "$ok" "003-example" "draft"
  write_spec "$ok/on-track/tracks/003-example/spec.md" "approved"
  write_tasks "$ok/on-track/tracks/003-example/tasks.md" "approved" "x"
  "$gate" --track 003-example --root "$ok" >/dev/null

  sed -i.bak 's/^id: 003-example$/id: 004-other/' "$ok/on-track/tracks/003-example/intent.md"
  expect_failure "gate with mismatched intent id" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "intent id mismatch: 004-other"
  mv "$ok/on-track/tracks/003-example/intent.md.bak" "$ok/on-track/tracks/003-example/intent.md"

  cat >"$ok/on-track/tracks/003-example/spec.md" <<'EOF'
---
status: draft
---
Files: fixture
Accept: fixture
EOF
  expect_failure "gate with no spec phases" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "spec has no ### Phase section"

  write_spec "$ok/on-track/tracks/003-example/spec.md" "draft"
  cat >>"$ok/on-track/tracks/003-example/spec.md" <<'EOF'

### Phase 2: empty accept
Done: fixture done
Files: fixture
Accept:
EOF
  expect_failure "gate with empty second phase Accept" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "Phase 2: empty accept missing or empty Accept:"

  write_spec "$ok/on-track/tracks/003-example/spec.md" "draft"
  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
Files: fixture
Validate: fixture
EOF
  expect_failure "gate with no task lines" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "tasks file has no task lines"

  write_tasks "$ok/on-track/tracks/003-example/tasks.md" "draft" " "
  cat >>"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
- [ ] Missing Validate. Files: fixture
EOF
  expect_failure "gate with task missing Validate" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "line 9 task missing or empty Validate:"

  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
## Group A (depends: Missing)
- [ ] Work. Files: fixture Validate: fixture
EOF
  expect_failure "gate with unknown group dependency" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "group A has unknown dependency Missing"

  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
## Group A (depends: A)
- [ ] Work. Files: fixture Validate: fixture
EOF
  expect_failure "gate with self-dependent group" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "group A depends on itself"

  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
## Group A
- [ ] Work. Files: fixture Validate: fixture
## Group A
- [ ] More. Files: fixture Validate: fixture
EOF
  expect_failure "gate with duplicate group names" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "duplicate group name A"

  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
## Group A (depends: B)
- [ ] Work. Files: fixture Validate: fixture
## Group B (depends: A)
- [ ] More. Files: fixture Validate: fixture
EOF
  expect_failure "gate with dependency cycle" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "dependency cycle involving"

  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
- [ ] Before group. Files: fixture Validate: fixture
## Group A
- [ ] Work. Files: fixture Validate: fixture
EOF
  expect_failure "gate with task before first group" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "task appears before first group header"

  cat >"$ok/on-track/tracks/003-example/tasks.md" <<'EOF'
---
status: draft
---
- [ ] Ungrouped. Files: fixture Validate: fixture
EOF
  expect_failure "gate with ungrouped tasks" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "tasks.md has no group header"
  expect_failure "gate completion with ungrouped tasks" "$gate" --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "tasks.md has no group header"

  write_tasks "$ok/on-track/tracks/003-example/tasks.md" "draft" "x"
  "$gate" --mode structure --track 003-example --root "$ok" >/dev/null

  write_plan "$ok/on-track/tracks/003-example/plan.md" "approved"
  expect_failure "gate with root plan.md" "$gate" --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "loose files outside assets/: plan.md"
  rm "$ok/on-track/tracks/003-example/plan.md"

  root_dir="$ok/on-track/tracks/003-example"
  for hidden_name in .notes .DS_Store; do
    printf 'hidden\n' >"$root_dir/$hidden_name"
    expect_failure "gate with hidden root entry $hidden_name" "$gate" --mode structure --track 003-example --root "$ok"
    assert_contains "$work/failure.out" "hidden root entry: $hidden_name"
    rm "$root_dir/$hidden_name"
  done

  printf 'not a directory\n' >"$root_dir/assets"
  expect_failure "gate with file assets" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "assets must be a directory"
  rm "$root_dir/assets"

  printf 'not a directory\n' >"$root_dir/spec"
  expect_failure "gate with file spec" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "loose files outside assets/: spec"
  rm "$root_dir/spec"

  mkdir "$root_dir/spec"
  expect_failure "gate with spec directory" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "loose files outside assets/: spec"
  rmdir "$root_dir/spec"

  mv "$root_dir/spec.md" "$work/spec-ok-spec.md"
  mkdir "$root_dir/spec.md"
  expect_failure "gate with directory spec.md" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "spec.md must be a file"
  rmdir "$root_dir/spec.md"
  mv "$work/spec-ok-spec.md" "$root_dir/spec.md"

  printf '# Decisions\n' >"$root_dir/decisions.md"
  expect_failure "gate with root decisions.md" "$gate" --mode structure --track 003-example --root "$ok"
  assert_contains "$work/failure.out" "loose files outside assets/: decisions.md"
  rm "$root_dir/decisions.md"
  spec_skill="$repo_root/skills/ot-spec/SKILL.md"
  spec_template="$repo_root/skills/ot-spec/assets/spec.md"
  tasks_template="$repo_root/skills/ot-spec/assets/tasks.md"
  assert_contains "$spec_skill" 'Done:'
  assert_contains "$spec_skill" 'Accept:'
  assert_contains "$spec_skill" '(Phase N)'
  assert_contains "$spec_skill" 'observable procedure with its expected observation'
  assert_contains "$spec_template" 'Done: the delivered, observable state when this phase closes.'
  assert_contains "$spec_template" 'Accept: the command with its expected result, or the observable procedure with its expected observation.'
  assert_not_contains "$spec_template" 'decisions.md'
  assert_not_contains "$spec_template" 'plan.md'
  assert_contains "$tasks_template" '(Phase 1):'
  assert_contains "$tasks_template" 'Validate: command or procedure with its expected result.'

  from_template="$work/spec-from-template"
  write_intent "$from_template" "005-template" "draft"
  base_dir="$from_template/on-track/tracks/005-template"
  sed 's/NNN-slug/005-template/g' "$spec_template" >"$base_dir/spec.md"
  sed -i.bak $'s/^Done:$/Done: phase two delivered state/; s/^Files:$/Files: fixture/; s/^Accept:$/Accept: run true, expect exit 0/' "$base_dir/spec.md"
  rm -f "$base_dir/spec.md.bak"
  sed 's/NNN-slug/005-template/g' "$tasks_template" >"$base_dir/tasks.md"
  "$gate" --mode structure --track 005-template --root "$from_template" >/dev/null
  pass "spec cycle"
}

run_flow() {
  intent_skill="$repo_root/skills/ot-intent/SKILL.md"
  spec_skill="$repo_root/skills/ot-spec/SKILL.md"
  implement_skill="$repo_root/skills/ot-implement/SKILL.md"
  tasks_template="$repo_root/skills/ot-spec/assets/tasks.md"
  signal_snippet="$repo_root/skills/ot-init/assets/AGENTS-snippet.md"
  for signal_file in "$signal_snippet" "$intent_skill" "$spec_skill" "$implement_skill"; do
    for contract_text in 'read as plain text' 'a message that only means proceed' 'a message that only means stop' 'an ambiguous one included'; do
      assert_contains "$signal_file" "$contract_text"
    done
    assert_not_contains "$signal_file" "pode continuar"
  done
  assert_contains "$signal_snippet" 'change no `status`, delete nothing, and undo no code'
  assert_contains "$signal_snippet" 'resumes when the user asks for that stage again'
  assert_contains "$signal_snippet" "keep the host's question tool for questions"
  assert_contains "$signal_snippet" 'In every lane the method never commits, pushes, or deploys on its own'
  assert_contains "$signal_snippet" 'Ship only marks the track `shipped`'
  assert_contains "$signal_snippet" 'happens only when the user asks for it, an approved task included'
  assert_contains "$intent_skill" 'Change no `status` and delete nothing'
  assert_contains "$spec_skill" 'Leave `spec.md` and `tasks.md` in `draft` and delete nothing'
  assert_contains "$implement_skill" 'keep the implemented code'
  for contract_text in 'investigate first' 'ask only blocking questions' 'one round per stage, at most four' 'your recommendation first' '"you decide"' '**Off Road** is the consulted way onto the Highway' "until that track's spec is approved" 'does not turn Off Road back on unless the user asks again' 'within the same cap' 'Off Road adds no field to any artifact and does not carry across sessions' 'a new session starts with it off until the user asks again' 'even when a handoff quotes the earlier request'; do
    assert_contains "$signal_snippet" "$contract_text"
  done
  assert_not_contains "$signal_snippet" 'until the conversation ends'
  assert_not_contains "$signal_snippet" 'the implement review asks before fixing'
  for contract_text in 'Ask every blocking question in one round, at most four' 'names the decision it unlocks' 'your recommendation first' 'marked `(delegated)`' 'There is one round in this stage' 'In Off Road' "until that track's spec is approved" 'A decision the user delegated is the other entry allowed there' 'Off Road adds no field to any artifact and does not carry across sessions' 'a new session starts with it off until the user asks again' 'even when a handoff quotes the earlier request'; do
    assert_contains "$intent_skill" "$contract_text"
  done
  assert_not_contains "$intent_skill" 'until the conversation ends'
  for contract_text in 'ask in rounds of at most four' 'marked `(delegated)`' 'Without delegation, do not invent answers to either kind' 'list delegated decisions so the user can veto them' 'In Off Road' 'until this spec is approved' 'Approval ends Off Road' 'Off Road adds no field to any artifact and does not carry across sessions' 'a new session starts with it off until the user asks again' 'even when a handoff quotes the earlier request'; do
    assert_contains "$spec_skill" "$contract_text"
  done
  assert_not_contains "$spec_skill" 'until the conversation ends'
  for mode_free_file in "$repo_root/skills/ot-intent/assets/intent.md" "$repo_root/skills/ot-spec/assets/spec.md" "$repo_root/skills/ot-spec/assets/tasks.md" "$repo_root/skills/ot-handoff/SKILL.md"; do
    assert_not_contains "$mode_free_file" 'Off Road'
  done
  while IFS= read -r mode_free_file; do
    assert_not_contains "$mode_free_file" 'Off Road'
  done < <(find "$repo_root/skills/ot-handoff/assets" -type f)
  for question_file in "$intent_skill" "$spec_skill"; do
    assert_not_contains "$question_file" 'three focused questions'
    assert_not_contains "$question_file" 'at most three per pass'
  done
  while IFS= read -r question_file; do
    assert_not_contains "$question_file" 'three focused questions'
    assert_not_contains "$question_file" 'at most three per pass'
  done < <(find "$repo_root/commands" -type f)
  assert_contains "$intent_skill" ". para continuar com a spec"
  assert_contains "$spec_skill" ". para implementar"
  assert_contains "$implement_skill" ". para ship"
  assert_contains "$implement_skill" 'Ship ends there: do not commit, push, or deploy unless the user asks'
  for contract_text in 'whose fix stays within the spec Files' 'leave every other finding open' 'assets/review.md' 'Severity | Finding | Location | Disposition' '`fixed` or `open`' 'naming each open `[important]`'; do
    assert_contains "$implement_skill" "$contract_text"
  done
  assert_not_contains "$implement_skill" 'finding or list it as open'
  assert_not_contains "$implement_skill" 'Off Road'
  assert_not_contains "$implement_skill" 'fix only the ones the user chooses'
  assert_contains "$implement_skill" "Delegate proportionally"
  assert_contains "$implement_skill" "each delegated task gets its own subagent"
  assert_not_contains "$implement_skill" "one task per agent"
  assert_contains "$implement_skill" "continue from the first open task"
  assert_contains "$implement_skill" "record the divergence in the track's"
  assert_contains "$implement_skill" "A dependent group starts only after every task of each group it depends on has passed Validate and is checked"
  assert_contains "$implement_skill" "do not create, edit, or delete any file listed in a dependent task's Files, including to stage work or to collect evidence"
  assert_contains "$implement_skill" "When a prerequisite task's Validate fails, stop before every dependent group and report the failure."
  assert_not_contains "$intent_skill" "Track concluida. Nenhuma implementacao necessaria."
  assert_contains "$implement_skill" "provenance"
  assert_contains "$implement_skill" "does not need"
  assert_not_contains "$implement_skill" "pointer; do not vendor"
  assert_contains "$tasks_template" "## Group"
  assert_contains "$tasks_template" "(depends:"
  for routing_file in "$intent_skill" "$repo_root/skills/ot-init/assets/AGENTS-snippet.md"; do
    for contract_text in 'splitting compound requests' 'before allocating anything' 'handle each part in its own lane' 'naming `ot-intent` or asking for a track or intent selects the Highway' 'asking to do it directly or without a track selects the Express lane' 'the request states what to build, with no open question that changes it' 'explicit choice wins in both directions' 'at most three files' 'no public contract (API, CLI flags, schema, consumed file format)' 'persisted data or migration' 'security control (authentication, authorization, secrets, permissions)' 'dependency (add, upgrade, remove)' 'reverting the diff alone' 'no data backfill or external side effect' 'Say in one sentence that the change takes the Express lane' 'implement, run the check, write a crumb, and report the change and result' 'any edit where an Express criterion is uncertain' 'one existing command or one observable check' 'stop before the edit that breaks it' 'name the failed criterion' 'start the Highway with `ot-intent`' 'never record it inside a track' 'Apart from the crumb, create no track or file under' 'do not regenerate the index' 'file only that ADR and regenerate the index' 'method never commits on its own' 'The Highway runs intent, spec, implement, and ship, and is the default'; do
      assert_contains "$routing_file" "$contract_text"
    done
  done
  for routing_file in "$intent_skill" "$repo_root/skills/ot-init/assets/AGENTS-snippet.md"; do
    for contract_text in 'The crumb is the note for the maintainer' 'a YAML block list, one path per line' 'on-track/crumbs/<YYYY-MM-DD-HHMMSSZ>-<slug>.md' 'Write it after the check, pass or fail' 'Frontmatter: `created` (UTC, ISO 8601) and `files`' '## Request' '## Cause' '## Changes' '## Verification' 'create it holding the single line `*`' 'reverse your own edits hunk by hunk' 'delete its crumb' 'read the crumbs oldest first' 'no longer differ from `HEAD`'; do
      assert_contains "$routing_file" "$contract_text"
    done
  done
  for routing_file in "$intent_skill" "$repo_root/skills/ot-init/assets/AGENTS-snippet.md" "$repo_root/commands/ot-intent.md"; do
    assert_not_contains "$routing_file" 'direct lane'
    assert_not_contains "$routing_file" 'full cycle'
  done
  assert_contains "$repo_root/commands/ot-intent.md" 'Split compound requests'
  assert_contains "$intent_skill" 'If reached without the user naming this skill'
  assert_contains "$repo_root/skills/ot-init/assets/AGENTS-snippet.md" 'before looking for a track or supporting artifact'
  assert_contains "$repo_root/skills/ot-init/assets/AGENTS-snippet.md" 'never scan the whole tree for discovery'
  assert_contains "$repo_root/skills/ot-init/assets/AGENTS-snippet.md" 'Highway implementation requires'
  assert_contains "$intent_skill" 'exactly one of four lists'
  assert_contains "$repo_root/skills/ot-intent/assets/intent.md" 'each with the path or command that showed it'
  assert_contains "$implement_skill" 'and `Verified by the agent` fact as given'
  assert_contains "$implement_skill" 'a verified fact'
  intent_template="$repo_root/skills/ot-intent/assets/intent.md"
  for heading in '### From the user' '### Proposed by the agent'; do
    assert_contains "$intent_template" "$heading"
  done
  for quality_file in "$intent_skill" "$intent_template"; do
    for contract_text in 'data loss, a security problem, or breaking the stated outcome' 'risk' 'never widen the outcome' 'question mark' 'decision it unlocks' 'owner when one exists'; do
      assert_contains "$quality_file" "$contract_text"
    done
  done
  assert_contains "$intent_skill" '`None.`'
  assert_contains "$intent_skill" 'method rules (approval, statuses, gates, lane rules)'
  assert_contains "$intent_skill" 'Fold spec-phase instructions into scope or drop them'
  assert_contains "$intent_skill" 'only when applicable'
  assert_contains "$intent_skill" 'list agent-proposed constraints so the user can veto them'
  assert_contains "$intent_skill" 'Problem or Proposed outcome rests on an entry under `Unverified assumptions`'
  assert_contains "$spec_skill" 'Every constraint in the intent is binding, regardless of provenance'
  pass "flow"
}

check_no_live_active() {
  package_root="$1"
  for live_file in "$package_root"/skills/ot-*/SKILL.md "$package_root"/skills/ot-*/assets/* "$package_root"/commands/ot-*.md; do
    [ -f "$live_file" ] || continue
    assert_not_contains "$live_file" 'status: active'
  done
}

run_active() {
  check_no_live_active "$repo_root"
  assert_not_matches "$index_script" 'legacy'
  active_target="$work/active-target"
  "$init_script" "$active_target" >/dev/null
  write_intent "$active_target" "001-example" "draft"
  "$index_script" "$active_target" >/dev/null
  cp "$active_target/on-track/INDEX.md" "$work/index-before-active-intent.md"
  write_intent "$active_target" "001-example" "active"
  expect_failure "index with active intent" "$index_script" "$active_target"
  assert_contains "$work/failure.err" "001-example invalid status: active"
  assert_contains "$work/failure.err" "INDEX not updated"
  cmp "$work/index-before-active-intent.md" "$active_target/on-track/INDEX.md" || fail "active intent changed INDEX.md"
  pass "active status rejected"
}

expect_index_frontmatter_rejection() {
  target_root="$1"
  expected="$2"
  expect_failure "index rejecting frontmatter: $expected" "$index_script" "$target_root"
  assert_contains "$work/failure.err" "$expected"
  cmp "$work/frontmatter-index.before" "$target_root/on-track/INDEX.md" || fail "frontmatter rejection changed INDEX.md"
}

expect_gate_frontmatter_rejection() {
  target_root="$1"
  expected="$2"
  expect_failure "gate rejecting frontmatter: $expected" "$gate" --mode structure --track 001-front --root "$target_root"
  assert_contains "$work/failure.out" "$expected"
}

run_frontmatter() {
  target="$work/frontmatter-target"
  "$init_script" "$target" >/dev/null
  track_dir="$target/on-track/tracks/001-front"
  intent="$track_dir/intent.md"
  write_intent "$target" "001-front" "draft"
  write_spec "$track_dir/spec.md" "draft"
  write_tasks "$track_dir/tasks.md" "draft" " "
  research="$target/on-track/research/front-research.md"
  cat >"$research" <<'EOF'
---
captured: 2026-09-20
owner: maintainer
---

# Research: front

## Question
Fixture.

## Conclusion
Fixture.

## Conflicts
None.

## Limitations
Fixture.

## Sources
- Fixture.
EOF
  "$index_script" "$target" >/dev/null
  "$gate" --mode structure --track 001-front --root "$target" >/dev/null
  cp "$target/on-track/INDEX.md" "$work/frontmatter-index.before"
  cp "$intent" "$work/frontmatter-intent.good"
  cp "$research" "$work/frontmatter-research.good"
  cp "$track_dir/spec.md" "$work/frontmatter-spec.good"
  cp "$track_dir/tasks.md" "$work/frontmatter-tasks.good"
  gate_intent="on-track/tracks/001-front/intent.md"

  printf -- '---\nid: 001-front\nstatus: draft\n' >"$intent"
  expect_index_frontmatter_rejection "$target" "001-front/intent.md frontmatter not closed"
  expect_gate_frontmatter_rejection "$target" "FAIL: $gate_intent frontmatter not closed"

  printf -- '---\nid: 001-front\nstatus: draft\nstatus: shipped\n---\n' >"$intent"
  expect_index_frontmatter_rejection "$target" "001-front/intent.md duplicate frontmatter field status"
  expect_gate_frontmatter_rejection "$target" "FAIL: $gate_intent duplicate frontmatter field status"

  printf -- '---\nid: 001-front\nstatus: draft\nrefs:\n  - slug\n---\n' >"$intent"
  expect_index_frontmatter_rejection "$target" "001-front/intent.md frontmatter line 5 is not a key: value field"
  expect_gate_frontmatter_rejection "$target" "FAIL: $gate_intent frontmatter line 5 is not a key: value field"

  printf -- '# Intent\n\n---\nid: 001-front\nstatus: draft\n---\n' >"$intent"
  expect_index_frontmatter_rejection "$target" "001-front missing id field"
  expect_gate_frontmatter_rejection "$target" "FAIL: intent without id"
  cp "$work/frontmatter-intent.good" "$intent"

  awk '{ print } $0 == "captured: 2026-09-20" { print "captured: 2026-09-21" }' "$work/frontmatter-research.good" >"$research"
  expect_index_frontmatter_rejection "$target" "front-research.md duplicate frontmatter field captured"
  cp "$work/frontmatter-research.good" "$research"

  awk '{ print } $0 == "status: draft" { print "status: approved" }' "$work/frontmatter-spec.good" >"$track_dir/spec.md"
  expect_gate_frontmatter_rejection "$target" "FAIL: on-track/tracks/001-front/spec.md duplicate frontmatter field status"
  cp "$work/frontmatter-spec.good" "$track_dir/spec.md"

  printf -- '---\nstatus: draft\n' >"$track_dir/tasks.md"
  expect_gate_frontmatter_rejection "$target" "FAIL: on-track/tracks/001-front/tasks.md frontmatter not closed"
  cp "$work/frontmatter-tasks.good" "$track_dir/tasks.md"

  "$index_script" "$target" >/dev/null
  "$gate" --mode structure --track 001-front --root "$target" >/dev/null

  template_count=0
  for template in "$repo_root"/skills/ot-*/assets/*; do
    [ -f "$template" ] || continue
    [ "$(head -n 1 "$template")" = "---" ] || continue
    template_count=$((template_count + 1))
    cp "$template" "$target/on-track/research/template-check.md"
    "$index_script" "$target" >/dev/null 2>"$work/template-check.err" || true
    if grep -Eq 'frontmatter not closed|duplicate frontmatter field|frontmatter line [0-9]+ is not a key: value field' "$work/template-check.err"; then
      fail "template frontmatter violates the canonical subset: $template"
    fi
  done
  rm "$target/on-track/research/template-check.md"
  [ "$template_count" -gt 0 ] || fail "no frontmatter templates found"
  pass "frontmatter subset"
}

# Check inline Markdown destinations without traversing generated documentation trees.
check_markdown_targets() {
  local page="$1" root="$2" images_only="$3" link target
  while IFS= read -r link; do
    case "$link" in
      ''|'#'*|//*|[[:alpha:]][[:alnum:]+.-]*:*) continue ;;
    esac
    target="${link%%#*}"
    target="${target%%\?*}"
    case "$target" in
      /*) target="$root$target" ;;
      *) target="$(dirname "$page")/$target" ;;
    esac
    [ -f "$target" ] || fail "$page has unresolved relative reference: $link"
  done < <(awk -v images_only="$images_only" '
    {
      line = $0
      pattern = images_only ? "!\\[[^]]*\\]\\([^)]*\\)" : "\\][(][^)]*[)]"
      while (match(line, pattern)) {
        link = substr(line, RSTART, RLENGTH)
        sub(/^.*\][(]/, "", link)
        sub(/[)]$/, "", link)
        sub(/[[:space:]]+[\042\047].*$/, "", link)
        sub(/^</, "", link)
        sub(/>$/, "", link)
        print link
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$page")
}

run_docs() {
  local docs_root="$repo_root/docs"
  local page relative_path field value link target
  if [ ! -d "$docs_root" ]; then
    echo "SKIP: docs (no docs directory)"
    return 0
  fi

  local language image_file
  for language in en pt; do
    assert_dir "$docs_root/images/$language"
    printf '%s\n' lanes.png lanes.svg support-context.png support-context.svg workflow.png workflow.svg >"$work/images-expected.paths"
    find "$docs_root/images/$language" -type f | sed "s|^$docs_root/images/$language/||" | LC_ALL=C sort >"$work/images-actual.paths"
    diff -u "$work/images-expected.paths" "$work/images-actual.paths" || fail "unexpected diagram files for $language"
    for image_file in "$docs_root/images/$language/"*.svg; do
      assert_not_matches "$image_file" 'Fast Track AI|fast-track-ai|/ft-'
    done
  done
  image_file="$(find "$docs_root/images" -maxdepth 1 -type f \( -iname '*.svg' -o -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.avif' -o -iname '*.bmp' -o -iname '*.ico' -o -iname '*.tif' -o -iname '*.tiff' \))"
  [ -z "$image_file" ] || fail "image files remain at docs/images/ root: $image_file"
  check_markdown_targets "$repo_root/README.md" "$repo_root" 0
  assert_file "$repo_root/README.pt-BR.md"
  check_markdown_targets "$repo_root/README.pt-BR.md" "$repo_root" 0

  assert_not_file "$docs_root/technical-guide.md"
  assert_dir "$docs_root/pt"
  assert_file "$docs_root/.vitepress/config.ts"
  (
    cd "$docs_root"
    find . \( -path './pt' -o -path './node_modules' -o -path './.vitepress' -o -path './images' \) -prune -o -type f -name '*.md' -print | LC_ALL=C sort
  ) >"$work/docs-en.paths"
  (
    cd "$docs_root/pt"
    find . \( -path './node_modules' -o -path './.vitepress' -o -path './images' \) -prune -o -type f -name '*.md' -print | LC_ALL=C sort
  ) >"$work/docs-pt.paths"
  if ! diff -u "$work/docs-en.paths" "$work/docs-pt.paths"; then
    fail "docs page parity differs between English and pt-BR"
  fi

  while IFS= read -r relative_path; do
    for page in "$docs_root/${relative_path#./}" "$docs_root/pt/${relative_path#./}"; do
      check_markdown_targets "$page" "$docs_root" 1
      # Require an opening and closing delimiter before reading scalar fields.
      awk 'NR == 1 && $0 != "---" { exit 1 } NR > 1 && $0 == "---" { closed = 1; exit } END { if (!closed) exit 1 }' "$page" || fail "$page has missing or unclosed frontmatter"
      for field in title description; do
        value="$(frontmatter_field "$page" "$field")"
        value="$(printf '%s\n' "$value" | sed 's/[[:space:]]*#.*$//; s/^[[:space:]]*//; s/[[:space:]]*$//')"
        case "$value" in
          ''|'""'|"''"|'null'|'~'|'|'|'>') fail "$page has empty frontmatter field: $field" ;;
        esac
      done
      assert_not_matches "$page" 'ft-(init|intent|spec|implement|research|assess|handoff)|—'
      assert_not_matches "$page" '^files: \['
      case "${relative_path#./}" in
        getting-started/migrating.md|getting-started/installation.md) ;;
        *) assert_not_contains "$page" 'fast-track-ai' ;;
      esac

      # Inspect inline Markdown destinations, including optional fragments.
      while IFS= read -r link; do
        case "$link" in
          //*|[[:alpha:]][[:alnum:]+.-]*:*) continue ;;
        esac
        target="${link%%#*}"
        case "$target" in
          /*) target="$docs_root$target" ;;
          *) target="$(dirname "$page")/$target" ;;
        esac
        [ -f "$target" ] || fail "$page has unresolved Markdown link: $link"
      done < <(awk '
        {
          line = $0
          while (match(line, /\]\([^)]*\.md(#[^)]*)?\)/)) {
            print substr(line, RSTART + 2, RLENGTH - 3)
            line = substr(line, RSTART + RLENGTH)
          }
        }
      ' "$page")
    done
  done <"$work/docs-en.paths"

  while IFS= read -r link; do
    target="${link%%#*}"
    case "$target" in
      */) target="${target}index.md" ;;
      *.md) ;;
      *) target="${target}.md" ;;
    esac
    [ -f "$docs_root$target" ] || fail "docs/.vitepress/config.ts has unresolved link: $link"
  done < <(awk '
    {
      line = $0
      while (match(line, /link:[[:space:]]*\047\/[^\047]*\047/)) {
        link = substr(line, RSTART, RLENGTH)
        sub(/^[^\047]*\047/, "", link)
        sub(/\047$/, "", link)
        print link
        line = substr(line, RSTART + RLENGTH)
      }
    }
  ' "$docs_root/.vitepress/config.ts")
  pass "docs"
}

run_isolation() {
  iso="$work/isolation"
  mkdir -p "$iso"
  for item in skills commands install.sh AGENTS.md README.md README.pt-BR.md evals; do
    cp -R "$repo_root/$item" "$iso/$item"
  done
  [ ! -e "$iso/on-track" ] || fail "isolation copy unexpectedly contains on-track/"
  ON_TRACK_ISOLATION_GUARD=1 bash "$iso/evals/run-evals.sh" all >/dev/null
  pass "isolation"
}

run_case() {
  case "$1" in
    self) run_self ;;
    init) run_init ;;
    index) run_index ;;
    approval) run_approval ;;
    install) run_install ;;
    resources) run_resources ;;
    workflows) run_workflows ;;
    refs) run_refs ;;
    decisions) run_decisions ;;
    handoff) run_handoff ;;
    spec) run_spec ;;
    flow) run_flow ;;
    active) run_active ;;
    frontmatter) run_frontmatter ;;
    docs) run_docs ;;
    isolation) run_isolation ;;
    *) fail "unknown eval: $1" ;;
  esac
}

if [ "$mode" = "all" ]; then
  for eval_name in self init index approval install resources workflows refs decisions handoff spec flow active frontmatter docs isolation; do
    if [ "$eval_name" = "isolation" ] && [ "${ON_TRACK_ISOLATION_GUARD:-}" = "1" ]; then
      continue
    fi
    run_case "$eval_name"
  done
  pass "all evals"
else
  run_case "$mode"
fi
