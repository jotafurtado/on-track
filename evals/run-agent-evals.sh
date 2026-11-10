#!/usr/bin/env bash
# run-agent-evals.sh runs optional, maintainer-only real-agent evaluations of the
# fast-track-ai workflow through a harness adapter (Kiro, Claude Code, or Codex)
# in disposable repositories. It is never called by run-evals.sh and never gates it.
#
# Usage: run-agent-evals.sh <selector> [--harness kiro|claude|codex] [--model MODEL]
#                           [--effort EFFORT] [--timeout SECONDS] [--keep-dir DIR]
# Selectors: compat revision approval failed-validation material-change resume direct-change compound-request artifact-threshold all
# Environment defaults: FAST_TRACK_AI_AGENT_MODEL, FAST_TRACK_AI_AGENT_EFFORT,
#   FAST_TRACK_AI_AGENT_TIMEOUT (seconds per turn, default 900), KIRO_CLI (default
#   kiro-cli), CLAUDE_CLI (default claude), CODEX_CLI (default codex).
#
# Each scenario prints one line: RESULT: <scenario> <pass|fail|inconclusive|prerequisite-unavailable>: <reason>
# A HARNESS: line precedes the results. Diagnostics live under <root>/<harness>/<scenario>.
# Exit codes: 0 no assertion failed (pass, inconclusive, or prerequisite-unavailable),
#             1 at least one scenario failed an assertion, 2 usage error.
# Exit zero is not package readiness: only a `pass` for every required cell is.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
agent_dir="$repo_root/evals/agent"
fixtures="$agent_dir/fixtures"
init_script="$repo_root/skills/ft-init/scripts/fast-track-ai-init.sh"
index_script="$repo_root/skills/ft-init/scripts/fast-track-ai-index.sh"
gate="$repo_root/skills/ft-spec/scripts/fast-track-ai-gate.sh"
# shellcheck source=agent/lib.sh
. "$agent_dir/lib.sh"

harness="kiro"
model="${FAST_TRACK_AI_AGENT_MODEL:-}"
effort="${FAST_TRACK_AI_AGENT_EFFORT:-}"
timeout_seconds="${FAST_TRACK_AI_AGENT_TIMEOUT:-900}"
keep_dir=""
selector=""
all_scenarios="compat revision approval failed-validation material-change resume direct-change compound-request artifact-threshold"
# Scenarios that need a resumed headless session with a subsequent prompt, or a
# material decision, run only after the compat spike reports `supported`.
continuation_scenarios="revision approval material-change"

usage() {
  echo "ERROR: $1" >&2
  echo "Usage: run-agent-evals.sh <compat|revision|approval|failed-validation|material-change|resume|direct-change|compound-request|artifact-threshold|all> [--harness kiro|claude|codex] [--model MODEL] [--effort EFFORT] [--timeout SECONDS] [--keep-dir DIR]" >&2
  exit 2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --harness) harness="${2:-}"; shift 2;;
    --model) model="${2:-}"; shift 2;;
    --effort) effort="${2:-}"; shift 2;;
    --timeout) timeout_seconds="${2:-}"; shift 2;;
    --keep-dir) keep_dir="${2:-}"; [ -n "$keep_dir" ] || usage "--keep-dir needs a directory"; shift 2;;
    -h|--help) usage "help requested";;
    -*) usage "unknown option: $1";;
    *) [ -z "$selector" ] || usage "only one selector is allowed"; selector="$1"; shift;;
  esac
done

[ -n "$selector" ] || usage "a selector is required"
case "$timeout_seconds" in ''|*[!0-9]*) usage "timeout must be a positive integer: $timeout_seconds";; esac
[ "$timeout_seconds" -gt 0 ] || usage "timeout must be a positive integer: $timeout_seconds"
if [ "$selector" = "all" ]; then
  selected="$all_scenarios"
else
  case " $all_scenarios " in *" $selector "*) selected="$selector";; *) usage "unknown selector: $selector";; esac
fi

# Harness dispatch: adapter, executable, native skill-discovery directory, label,
# and the effort levels the harness CLI documents. Unknown harnesses and
# unsupported settings are rejected before any agent starts.
case "$harness" in
  kiro) adapter="$agent_dir/kiro-adapter.sh"; cli_var=KIRO_CLI; cli="${KIRO_CLI:-kiro-cli}"; native_dir=.kiro; label="Kiro CLI"; effort_levels="low medium high xhigh max";;
  claude) adapter="$agent_dir/claude-adapter.sh"; cli_var=CLAUDE_CLI; cli="${CLAUDE_CLI:-claude}"; native_dir=.claude; label="Claude Code CLI"; effort_levels="low medium high xhigh max";;
  codex) adapter="$agent_dir/codex-adapter.sh"; cli_var=CODEX_CLI; cli="${CODEX_CLI:-codex}"; native_dir=.agents; label="Codex CLI"; effort_levels="none minimal low medium high xhigh max";;
  *) usage "unknown harness: ${harness:-<empty>} (expected kiro, claude, or codex)";;
esac
if [ -n "$effort" ]; then
  case " $effort_levels " in *" $effort "*) ;; *) usage "effort '$effort' is not supported by $harness (supported: $effort_levels)";; esac
fi

if [ -n "$keep_dir" ]; then
  mkdir -p "$keep_dir"
  diag_root="$(cd "$keep_dir" && pwd)"
else
  tmp_base="${TMPDIR:-/tmp}"
  diag_root="$(mktemp -d "${tmp_base%/}/fast-track-ai-agent-evals.XXXXXX")"
fi

count_pass=0
count_fail=0
count_inconclusive=0
count_prereq=0
retained=0

echo "HARNESS: $harness"

finish() {
  echo "SUMMARY: pass=$count_pass fail=$count_fail inconclusive=$count_inconclusive prerequisite-unavailable=$count_prereq"
  if [ "$retained" -eq 0 ] && [ -z "$keep_dir" ]; then
    rm -rf "$diag_root"
  else
    echo "DIAGNOSTICS ROOT: $diag_root"
  fi
  [ "$count_fail" -eq 0 ] || exit 1
  exit 0
}

# record_result <scenario> <classification> <reason>
record_result() {
  local scenario="$1" classification="$2" reason="$3" scenario_dir
  echo "RESULT: $scenario $classification: $reason"
  case "$classification" in
    pass) count_pass=$((count_pass + 1));;
    fail) count_fail=$((count_fail + 1));;
    inconclusive) count_inconclusive=$((count_inconclusive + 1));;
    prerequisite-unavailable) count_prereq=$((count_prereq + 1));;
  esac
  scenario_dir="$diag_root/$harness/$scenario"
  if [ -d "$scenario_dir" ]; then
    jq -n -c --arg harness "$harness" --arg scenario "$scenario" --arg result "$classification" --arg reason "$reason" \
      --arg model "$model" --arg effort "$effort" --argjson timeout "$timeout_seconds" \
      '{harness: $harness, scenario: $scenario, result: $result, reason: $reason, model: $model, effort: $effort, timeoutSeconds: $timeout}' >"$scenario_dir/result.json"
    if [ "$classification" = "pass" ] && [ -z "$keep_dir" ]; then
      rm -rf "$scenario_dir"
    else
      retained=1
      echo "DIAGNOSTICS: $scenario $scenario_dir"
    fi
  fi
}

# prerequisite_reason: the missing prerequisite of the selected harness, or empty.
# The executable and tools are checked before any CLI is invoked.
prerequisite_reason() {
  command -v "$cli" >/dev/null 2>&1 || { echo "$label not found: $cli"; return; }
  for tool in jq rsync shasum git; do
    command -v "$tool" >/dev/null 2>&1 || { echo "required tool not found: $tool"; return; }
  done
  case "$harness" in
    kiro) "$cli" whoami >/dev/null 2>&1 </dev/null || { echo "$label is not authenticated ($cli whoami failed); run kiro-cli login"; return;};;
    claude) "$cli" auth status 2>/dev/null </dev/null | jq -e '.loggedIn == true' >/dev/null 2>&1 || { echo "$label is not authenticated ($cli auth status does not report loggedIn); run claude auth login"; return;};;
    codex) "$cli" login status >/dev/null 2>&1 </dev/null || { echo "$label is not authenticated ($cli login status failed); run codex login"; return;};;
  esac
  echo ""
}

missing_prerequisite="$(prerequisite_reason)"
if [ -n "$missing_prerequisite" ]; then
  for selected_scenario in $selected; do
    record_result "$selected_scenario" prerequisite-unavailable "$missing_prerequisite"
  done
  finish
fi

cli_version="$("$cli" --version 2>/dev/null </dev/null | head -1 || true)"

# ---------------------------------------------------------------------------
# Per-scenario assertion state. Verdicts come only from checkpoints, method
# artifacts, frontmatter, task state, command outcomes, and recorded actions.

s_fail_count=0
s_inconclusive_count=0
s_pass_count=0
s_first_fail=""
s_first_inconclusive=""
s_prereq=""

reset_assertions() {
  s_fail_count=0; s_inconclusive_count=0; s_pass_count=0
  s_first_fail=""; s_first_inconclusive=""; s_prereq=""
}

assert_ok() {
  s_pass_count=$((s_pass_count + 1)); echo "PASS $1" >>"$sdir/assertions.log"
}

assert_bad() {
  s_fail_count=$((s_fail_count + 1)); echo "FAIL $1" >>"$sdir/assertions.log"
  [ -n "$s_first_fail" ] || s_first_fail="$1"
}

assert_unknown() {
  s_inconclusive_count=$((s_inconclusive_count + 1)); echo "INCONCLUSIVE $1" >>"$sdir/assertions.log"
  [ -n "$s_first_inconclusive" ] || s_first_inconclusive="$1"
}

verdict() {
  local scenario="$1"
  if [ -n "$s_prereq" ]; then
    record_result "$scenario" prerequisite-unavailable "$s_prereq"
  elif [ "$s_fail_count" -gt 0 ]; then
    record_result "$scenario" fail "$s_first_fail ($s_fail_count failed, $s_inconclusive_count inconclusive; see assertions.log)"
  elif [ "$s_inconclusive_count" -gt 0 ]; then
    record_result "$scenario" inconclusive "$s_first_inconclusive ($s_inconclusive_count inconclusive; see assertions.log)"
  else
    record_result "$scenario" pass "$s_pass_count assertions passed"
  fi
}

# stage_turns <scenario>: copies the canonical turn prompts into the scenario
# directory. The first sentence naming "this repository" gains the discovery
# location hint of the selected harness; decisions, continuation inputs, and every
# other prompt stay byte-identical to the fixtures.
stage_turns() {
  local scenario="$1" file
  turns_staged="$sdir/turns"
  mkdir -p "$turns_staged"
  for file in "$fixtures/$scenario/turns"/turn-*.txt; do
    awk -v hint="The skill is available under $native_dir/skills/." '
      !done && (i = index($0, " in this repository.")) > 0 { $0 = substr($0, 1, i + 19) " " hint substr($0, i + 20); done = 1 }
      { print }' "$file" >"$turns_staged/$(basename "$file")"
  done
}

# prepare_workspace <scenario> <method|plain>
prepare_workspace() {
  local scenario="$1" kind="$2" skill
  sdir="$diag_root/$harness/$scenario"
  rm -rf "$sdir"
  mkdir -p "$sdir"
  ws="$sdir/workspace"
  evidence="$sdir/evidence"
  mkdir -p "$ws"
  : >"$sdir/assertions.log"
  stage_turns "$scenario"
  if [ "$kind" = "method" ]; then
    "$init_script" "$ws" >/dev/null
    if [ -d "$fixtures/$scenario/workspace" ]; then
      rsync -a "$fixtures/$scenario/workspace/" "$ws/"
    fi
    "$index_script" "$ws" >/dev/null
    mkdir -p "$ws/$native_dir/skills"
    for skill in "$repo_root"/skills/ft-*; do
      cp -R "$skill" "$ws/$native_dir/skills/"
    done
  fi
  git -C "$ws" init -q
  printf '.kiro/\n.claude/\n.agents/\n' >>"$ws/.git/info/exclude"
  git -C "$ws" add -A
  git -C "$ws" -c user.name=fast-track-ai-eval -c user.email=eval@example.invalid -c commit.gpgsign=false -c tag.gpgsign=false commit -q --allow-empty -m "fixture baseline"
}

run_turns() {
  adapter_args=(--workspace "$ws" --turns-dir "$turns_staged" --out "$evidence" --timeout "$timeout_seconds")
  [ -n "$model" ] && adapter_args+=(--model "$model")
  [ -n "$effort" ] && adapter_args+=(--effort "$effort")
  adapter_rc=0
  env "$cli_var=$cli" "$adapter" "${adapter_args[@]}" >"$sdir/adapter.log" 2>&1 || adapter_rc=$?
  [ "$adapter_rc" -eq 0 ] || assert_unknown "adapter exited $adapter_rc"
  return "$adapter_rc"
}

turn_field() {
  jq -r --argjson n "$1" --arg field "$2" 'select(.turn == $n) | .[$field] // empty | tostring' "$evidence/turns.jsonl" 2>/dev/null || true
}

# require_turns <count>: every turn up to count succeeded; otherwise records why.
require_turns() {
  n=1
  while [ "$n" -le "$1" ]; do
    outcome="$(turn_field "$n" outcome)"
    case "$outcome" in
      success) ;;
      "") assert_unknown "turn $n did not run"; return 1;;
      auth-failure) s_prereq="turn $n reported a $label authentication failure"; return 1;;
      timeout) assert_unknown "turn $n timed out after ${timeout_seconds}s"; return 1;;
      *) assert_unknown "turn $n outcome: $outcome"; return 1;;
    esac
    n=$((n + 1))
  done
  return 0
}

checkpoint_dir() { printf '%s/checkpoints/turn-%02d' "$evidence" "$1"; }
checkpoint_manifest() { printf '%s/checkpoints/turn-%02d.manifest' "$evidence" "$1"; }
actions_file() { printf '%s/turn-%02d.actions.jsonl' "$evidence" "$1"; }

# changed_paths <from> <to>: paths added, removed, or modified between checkpoints.
changed_paths() {
  awk 'NR == FNR { a[substr($0, 67)] = substr($0, 1, 64); next }
       { p = substr($0, 67); b[p] = substr($0, 1, 64) }
       END { for (p in a) if (!(p in b) || a[p] != b[p]) print p; for (p in b) if (!(p in a)) print p }' \
    "$(checkpoint_manifest "$1")" "$(checkpoint_manifest "$2")" | LC_ALL=C sort
}

product_changes() { changed_paths "$1" "$2" | grep -v '^fast-track-ai/' || true; }

status_at() {
  file="$(checkpoint_dir "$1")/$2"
  [ -f "$file" ] || { echo "missing"; return; }
  awk '/^---$/{section++; next} section == 1 && index($0, "status:") == 1 { sub("^status:[[:space:]]*", ""); print; exit }' "$file"
}

# jq_actions <turn> <jq args...>: jq over the turn's normalized action array.
jq_actions() {
  local n="$1"; shift
  ftai_actions "$(actions_file "$n")" "$@"
}

turn_complete() { ftai_turn_complete "$evidence/turns.jsonl" "$1"; }
turn_incomplete_reasons() { ftai_turn_incomplete_reasons "$evidence/turns.jsonl" "$1"; }

product_edit_count() { jq_actions "$1" "[.[] | select(.kind == \"edit\") | select(.status != \"failed\") | select(any(.paths[]; $FTAI_PRODUCT_FILTER))] | length"; }
edited_paths() { jq_actions "$1" '.[] | select(.kind == "edit") | select(.status != "failed") | .paths[]' | LC_ALL=C sort -u; }
shell_commands() { jq_actions "$1" '.[] | select(.kind == "execute") | .command // empty'; }

# uncovered_product_changes <from> <to> <turn>: product changes with no edit action.
uncovered_product_changes() {
  product_changes "$1" "$2" >"$sdir/product-changes.txt"
  edited_paths "$3" >"$sdir/edited-paths.txt"
  LC_ALL=C comm -23 "$sdir/product-changes.txt" "$sdir/edited-paths.txt"
}

assert_planning_status() {
  checkpoint="$1"; expected="$2"; track="$3"
  for artifact in spec.md tasks.md; do
    actual="$(status_at "$checkpoint" "fast-track-ai/tracks/$track/$artifact")"
    if [ "$actual" = "$expected" ]; then
      assert_ok "$artifact is $expected at checkpoint $checkpoint"
    else
      assert_bad "$artifact is '$actual' at checkpoint $checkpoint, expected $expected"
    fi
  done
}

assert_no_product_change() {
  changes="$(product_changes "$1" "$2" | tr '\n' ' ')"
  if [ -z "$changes" ]; then
    assert_ok "no product change between checkpoints $1 and $2"
  else
    assert_bad "product change between checkpoints $1 and $2: $changes"
  fi
}

# assert_no_product_edit_action <turn>: a recorded product edit fails; absence of
# edits passes only when the turn's action stream is complete enough to prove it.
assert_no_product_edit_action() {
  edits="$(product_edit_count "$1")"
  if [ "${edits:-0}" -gt 0 ]; then
    assert_bad "$edits product edit actions recorded in turn $1"
  elif [ "$(turn_complete "$1")" != "true" ]; then
    assert_unknown "turn $1 action stream is incomplete ($(turn_incomplete_reasons "$1")); absence of product edit actions not verified"
  else
    assert_ok "no product edit action in turn $1"
  fi
}

assert_no_checked_task() {
  tasks_path="$(checkpoint_dir "$1")/fast-track-ai/tracks/$2/tasks.md"
  if grep -Eq '^[[:space:]]*- \[[xX]\]' "$tasks_path" 2>/dev/null; then
    assert_bad "a task is checked in tasks.md at checkpoint $1"
  else
    assert_ok "no task is checked at checkpoint $1"
  fi
}

assert_not_shipped() {
  intent_status="$(status_at "$1" "fast-track-ai/tracks/$2/intent.md")"
  if [ "$intent_status" = "shipped" ]; then
    assert_bad "intent is shipped at checkpoint $1"
  else
    assert_ok "intent is not shipped at checkpoint $1 ($intent_status)"
  fi
}

# assert_staged_skill <skill>: the evaluated skill was loaded from the staged
# package under the harness's native discovery directory, proven by native tool
# evidence. A copy loaded from anywhere else never counts as the evaluated package.
assert_staged_skill() {
  local skill="$1" staged outside
  staged="$(jq -s -r --arg s "$skill" '[.[] | (.skillLoads // [])[] | select(.skill == $s and .staged == true)] | length' "$evidence/turns.jsonl" 2>/dev/null || echo 0)"
  outside="$(jq -s -r --arg s "$skill" '[.[] | (.skillLoads // [])[] | select(.skill == $s and .staged == false) | .path] | join(", ")' "$evidence/turns.jsonl" 2>/dev/null || true)"
  if [ "${staged:-0}" -gt 0 ]; then
    assert_ok "$skill was loaded from the staged $native_dir/skills location"
  elif [ -n "$outside" ]; then
    assert_unknown "$skill was loaded only from outside the staged package ($outside)"
  else
    assert_unknown "no machine-verifiable load of the staged $skill was observed"
  fi
}

# task_checkbox <checkpoint> <track> <task label>: prints open, checked, or missing.
task_checkbox() {
  awk -v label="$3" 'index($0, label) && match($0, /^[[:space:]]*- \[[ xX]\]/) { c = substr($0, RSTART + RLENGTH - 2, 1); print (c == " " ? "open" : "checked"); found = 1; exit } END { if (!found) print "missing" }' \
    "$(checkpoint_dir "$1")/fast-track-ai/tracks/$2/tasks.md" 2>/dev/null || echo missing
}

# ---------------------------------------------------------------------------
# Compatibility spike: a headless session must accept a resumed subsequent prompt.

compat_result=""
compat_reason=""

scenario_compat() {
  reset_assertions
  prepare_workspace compat plain
  run_turns || true
  expected_token="$(tr -d '[:space:]' <"$fixtures/compat/expected-token")"
  first="$(turn_field 1 outcome)"
  second="$(turn_field 2 outcome)"
  first_session="$(turn_field 1 sessionId)"
  second_session="$(turn_field 2 sessionId)"
  if [ "$first" = "auth-failure" ] || [ "$second" = "auth-failure" ]; then
    compat_result="auth-failure"; compat_reason="$label reported an authentication failure"
  elif [ "$first" = "timeout" ] || [ "$second" = "timeout" ]; then
    compat_result="timeout"; compat_reason="a compat turn exceeded ${timeout_seconds}s"
  elif [ "$first" != "success" ]; then
    compat_result="unsupported"; compat_reason="the first headless turn did not succeed (${first:-not run})"
  elif [ -z "$first_session" ]; then
    compat_result="unsupported"; compat_reason="the first headless turn reported no session id"
  elif [ "$second" != "success" ]; then
    compat_result="unsupported"; compat_reason="the resumed turn did not succeed (${second:-not run})"
  elif [ "$second_session" != "$first_session" ]; then
    compat_result="unsupported"; compat_reason="the resumed turn reported session $second_session instead of $first_session"
  elif [ "$(tr -d '[:space:]' <"$(checkpoint_dir 2)/token.txt" 2>/dev/null)" != "$expected_token" ]; then
    compat_result="unsupported"; compat_reason="the resumed turn did not write the token given only in the first turn"
  else
    compat_result="supported"; compat_reason="session $first_session resumed with a subsequent prompt"
  fi
  mkdir -p "$evidence"
  jq -n -c --arg harness "$harness" --arg result "$compat_result" --arg reason "$compat_reason" --arg version "$cli_version" \
    '{capability: "headless-continuation", harness: $harness, result: $result, reason: $reason, cliVersion: $version}' >"$evidence/capability.json"
  echo "CAPABILITY $compat_result $compat_reason" >>"$sdir/assertions.log"
  case "$compat_result" in
    supported) record_result compat pass "headless continuation supported: $compat_reason";;
    auth-failure) record_result compat prerequisite-unavailable "headless continuation auth-failure: $compat_reason";;
    *) record_result compat inconclusive "headless continuation $compat_result: $compat_reason";;
  esac
}

ensure_compat() {
  [ -n "$compat_result" ] || scenario_compat
}

# ---------------------------------------------------------------------------
# Workflow scenarios.

scenario_revision() {
  reset_assertions
  prepare_workspace revision method
  track=001-greeting
  if run_turns && require_turns 2; then
    assert_staged_skill ft-spec
    if [ "$(status_at 1 "fast-track-ai/tracks/$track/spec.md")" = "missing" ] || [ "$(status_at 1 "fast-track-ai/tracks/$track/tasks.md")" = "missing" ]; then
      assert_unknown "turn 1 did not write spec.md and tasks.md"
    else
      assert_planning_status 1 draft "$track"
      assert_no_product_change 0 1
      assert_planning_status 2 draft "$track"
      assert_no_product_change 0 2
      assert_no_product_edit_action 2
      assert_no_checked_task 2 "$track"
      assert_not_shipped 2 "$track"
    fi
  fi
  verdict revision
}

scenario_approval() {
  reset_assertions
  prepare_workspace approval method
  track=001-greeting
  if run_turns && require_turns 2; then
    assert_staged_skill ft-spec
    if [ "$(status_at 1 "fast-track-ai/tracks/$track/spec.md")" = "missing" ] || [ "$(status_at 1 "fast-track-ai/tracks/$track/tasks.md")" = "missing" ]; then
      assert_unknown "turn 1 did not write spec.md and tasks.md"
    else
      assert_planning_status 1 draft "$track"
      assert_no_product_change 0 1
      assert_planning_status 2 approved "$track"
      # Order: approval writes precede the first product edit, when the native
      # stream proves it. Batched, concurrent, or unobserved edits prove nothing.
      if [ "$(turn_complete 2)" != "true" ]; then
        assert_unknown "turn 2 action stream is incomplete ($(turn_incomplete_reasons 2)); approval order not verified"
      elif [ -z "$(product_changes 1 2)" ]; then
        assert_unknown "no implementation product change after approval; approval order not verified"
      elif [ -n "$(uncovered_product_changes 1 2 2)" ]; then
        assert_unknown "product changes without an edit action ($(uncovered_product_changes 1 2 2 | tr '\n' ' ')); approval order not verified"
      else
        order="$(ftai_approval_order "$(actions_file 2)" "fast-track-ai/tracks/$track/spec.md" "fast-track-ai/tracks/$track/tasks.md")"
        case "$order" in
          ok) assert_ok "separate completed approval writes finished before every product edit started";;
          violation) assert_bad "a product edit started before an approval write completed";;
          *) assert_unknown "${order#unproven: }; approval order not verified";;
        esac
      fi
    fi
  fi
  verdict approval
}

scenario_failed_validation() {
  reset_assertions
  prepare_workspace failed-validation method
  track=001-greeting
  if run_turns && require_turns 1; then
    assert_staged_skill ft-implement
    if shell_commands 1 | grep -Fq 'check-greeting.sh'; then
      assert_ok "the failing Validate command ran"
    else
      assert_unknown "the failing Validate command was not observed running"
    fi
    for label_text in "Task 1 (Phase 1)" "Task 2 (Phase 2)"; do
      box="$(task_checkbox 1 "$track" "$label_text")"
      if [ "$box" = "open" ]; then assert_ok "$label_text stays open"; else assert_bad "$label_text is $box"; fi
    done
    if [ -e "$(checkpoint_dir 1)/farewell.txt" ]; then
      assert_bad "dependent work started: farewell.txt exists"
    else
      assert_ok "dependent farewell.txt was not created"
    fi
    if edited_paths 1 | grep -Fxq 'farewell.txt'; then
      assert_bad "an edit action targeted dependent farewell.txt"
    elif [ "$(turn_complete 1)" != "true" ]; then
      assert_unknown "turn 1 action stream is incomplete ($(turn_incomplete_reasons 1)); absence of an edit of farewell.txt not verified"
    elif [ "$(ftai_shell_may_mutate "$(actions_file 1)" farewell.txt)" = "yes" ]; then
      assert_unknown "a shell command mentions farewell.txt with a mutating construct; absence of an edit not verified"
    else
      assert_ok "no edit action targeted dependent farewell.txt"
    fi
    if changed_paths 0 1 | grep -Fxq 'scripts/check-greeting.sh'; then
      assert_bad "the failing Validate script was edited"
    else
      assert_ok "the failing Validate script is unchanged"
    fi
    assert_not_shipped 1 "$track"
    # Ship is offered only when every acceptance row is met, so a durable
    # all-met acceptance record means completion was offered.
    acceptance="$(checkpoint_dir 1)/fast-track-ai/tracks/$track/assets/acceptance.md"
    if [ ! -f "$acceptance" ]; then
      assert_ok "no acceptance record, so completion was not offered"
    elif grep -Eiq '\|[[:space:]]*pending[[:space:]]*\|' "$acceptance"; then
      assert_ok "acceptance record keeps a pending row, so completion was not offered"
    else
      assert_bad "acceptance record has no pending row, so completion could be offered"
    fi
    if "$gate" --track "$track" --root "$(checkpoint_dir 1)" >"$sdir/gate.out" 2>&1; then
      assert_bad "the completion gate passes, so the track could be shipped"
    else
      assert_ok "the completion gate rejects the track"
    fi
  fi
  verdict failed-validation
}

scenario_material_change() {
  reset_assertions
  prepare_workspace material-change method
  track=001-greeting
  if run_turns && require_turns 1; then
    assert_staged_skill ft-implement
    assert_planning_status 1 draft "$track"
    assert_no_product_change 0 1
    assert_no_product_edit_action 1
    assert_no_checked_task 1 "$track"
    assert_not_shipped 1 "$track"
  fi
  verdict material-change
}

scenario_resume() {
  reset_assertions
  prepare_workspace resume method
  track=001-letters
  if run_turns && require_turns 1; then
    assert_staged_skill ft-implement
    validation_execution="$(ftai_validation_execution "$(actions_file 1)" scripts/validate-alpha.sh FTAI_VALIDATION_EXECUTED:resume:alpha "$(cat "$(checkpoint_dir 0)/scripts/validate-alpha.sh")")"
    if [ -e "$(checkpoint_dir 1)/.eval-validate-alpha-ran" ] || [ "$validation_execution" = "executed" ]; then
      assert_bad "the checked Task 1 Validate was rerun"
    elif [ "$(turn_complete 1)" != "true" ] || [ "$validation_execution" = "unproven" ]; then
      assert_unknown "the checked Task 1 Validate has an opaque or unobserved invocation reference"
    else
      assert_ok "the checked Task 1 Validate was not rerun"
    fi
    if changed_paths 0 1 | grep -Fxq 'alpha.txt'; then assert_bad "checked alpha.txt changed"; else assert_ok "checked alpha.txt is unchanged"; fi
    box="$(task_checkbox 1 "$track" "Task 1 (Phase 1)")"
    if [ "$box" = "checked" ]; then assert_ok "Task 1 stays checked"; else assert_bad "Task 1 is $box"; fi
    if [ ! -e "$(checkpoint_dir 1)/beta.txt" ] && [ "$(task_checkbox 1 "$track" "Task 2 (Phase 1)")" != "checked" ]; then
      assert_unknown "the agent did not progress on the first open task"
    elif [ "$(turn_complete 1)" != "true" ]; then
      assert_unknown "turn 1 action stream is incomplete ($(turn_incomplete_reasons 1)); task order not verified"
    elif [ -n "$(uncovered_product_changes 0 1 1)" ]; then
      assert_unknown "product changes without an edit action ($(uncovered_product_changes 0 1 1 | tr '\n' ' ')); task order not verified"
    else
      order="$(ftai_first_edit "$(actions_file 1)" beta.txt)"
      case "$order" in
        ok) assert_ok "every other product edit is proven to follow the edit of the first open task (beta.txt)";;
        violation) assert_bad "a product edit other than beta.txt completed before the edit of beta.txt";;
        missing) assert_bad "no product edit action targeted the first open task (beta.txt)";;
        *) assert_unknown "${order#unproven: }; task order not verified";;
      esac
    fi
  fi
  verdict resume
}

# Single-turn scenarios still need both checkpoints and complete action coverage
# before absence can pass. Durable violations below fail even with coverage gaps.
assert_single_turn_checkpoints() {
  local checkpoint
  for checkpoint in 0 1; do
    if [ ! -f "$(checkpoint_manifest "$checkpoint")" ] || [ ! -d "$(checkpoint_dir "$checkpoint")" ]; then
      assert_unknown "checkpoint $checkpoint is missing; final-state absence not verified"
      return 1
    fi
  done
  if [ "$(turn_complete 1)" != "true" ]; then
    assert_unknown "turn 1 action stream is incomplete ($(turn_incomplete_reasons 1)); absence not verified"
  fi
}

# new_track_dirs: includes empty track directories, which file manifests omit.
new_track_dirs() {
  local checkpoint
  for checkpoint in 0 1; do
    : >"$sdir/tracks-$checkpoint.txt"
    if [ -d "$(checkpoint_dir "$checkpoint")/fast-track-ai/tracks" ]; then
      find "$(checkpoint_dir "$checkpoint")/fast-track-ai/tracks" -mindepth 1 -maxdepth 1 -type d \
        -exec basename {} \; | LC_ALL=C sort >"$sdir/tracks-$checkpoint.txt"
    fi
  done
  LC_ALL=C comm -13 "$sdir/tracks-0.txt" "$sdir/tracks-1.txt"
}

# assert_intent_track: selects the sole newly allocated track, if it has intent.
assert_intent_track() {
  local tracks count
  tracks="$(new_track_dirs)"
  count="$(printf '%s\n' "$tracks" | grep -c . || true)"
  if [ "$count" -eq 0 ]; then
    assert_unknown "no new intent track was written"
    return 1
  elif [ "$count" -ne 1 ]; then
    assert_bad "$count new track directories, expected exactly one"
    return 1
  fi
  track="$tracks"
  if [ ! -f "$(checkpoint_dir 1)/fast-track-ai/tracks/$track/intent.md" ]; then
    assert_unknown "the new track has no intent.md"
    return 1
  fi
  assert_ok "exactly one new track with intent.md"
}

scenario_direct_change() {
  reset_assertions
  prepare_workspace direct-change method
  if run_turns && require_turns 1 && assert_single_turn_checkpoints; then
    # Include empty directories and symlink targets, which file manifests omit.
    method_changes="$(changed_paths 0 1 | grep '^fast-track-ai/' || true)"
    for checkpoint in 0 1; do
      (cd "$(checkpoint_dir "$checkpoint")"
        if [ -e fast-track-ai ]; then
          find fast-track-ai ! -type f | while IFS= read -r entry; do
            printf '%s' "$entry"
            if [ -L "$entry" ]; then printf ' -> %s' "$(readlink "$entry")"; fi
            printf '\n'
          done | LC_ALL=C sort
        fi) >"$sdir/method-dirs-$checkpoint.txt"
    done
    directory_changes="$(LC_ALL=C comm -3 "$sdir/method-dirs-0.txt" "$sdir/method-dirs-1.txt")"
    if [ -n "$method_changes$directory_changes" ]; then
      assert_bad "direct change modified fast-track-ai paths: $method_changes $directory_changes"
    elif [ "$(turn_complete 1)" = "true" ]; then
      assert_ok "no path under fast-track-ai changed"
    fi
    if [ ! -f "$(checkpoint_dir 1)/greeting.txt" ] || [ "$(cat "$(checkpoint_dir 1)/greeting.txt")" != 'hello world' ] || [ "$(wc -l <"$(checkpoint_dir 1)/greeting.txt" | tr -d ' ')" -gt 1 ]; then
      if [ -z "$(product_changes 0 1)" ] && [ -z "$method_changes$directory_changes" ]; then
        assert_unknown "no product or method change; direct lane was not reached"
      else
        assert_bad "greeting.txt does not hold hello world"
      fi
    else
      assert_ok "greeting.txt holds hello world"
    fi
  fi
  verdict direct-change
}

scenario_compound_request() {
  reset_assertions
  prepare_workspace compound-request method
  if run_turns && require_turns 1 && assert_single_turn_checkpoints; then
    operation_execution="$(ftai_validation_execution "$(actions_file 1)" scripts/report.sh FTAI_OPERATION_EXECUTED:compound:report "$(cat "$(checkpoint_dir 0)/scripts/report.sh")")"
    if [ -f "$(checkpoint_dir 1)/.eval-report-ran" ] || [ "$operation_execution" = "executed" ]; then
      assert_ok "the operational report ran"
    else
      assert_unknown "the operational report has no execution proof ($operation_execution)"
    fi
    # The report's own marker is the sole allowed product change, deliberately
    # excluded here; edits to its script or any other product file still fail.
    changes="$(product_changes 0 1 | grep -v '^\.eval-report-ran$' || true)"
    if [ -n "$changes" ]; then assert_bad "unexpected compound-request product change: $changes"; else assert_ok "no product change except the report marker"; fi
    if edited_paths 1 | grep -Fxq 'scripts/greet.sh'; then
      assert_bad "a product edit action targeted scripts/greet.sh"
    elif [ "$(turn_complete 1)" != "true" ]; then
      assert_unknown "absence of a greet.sh edit action not verified"
    elif [ "$(ftai_shell_may_mutate "$(actions_file 1)" scripts/greet.sh)" = "yes" ]; then
      assert_unknown "a shell command may mutate scripts/greet.sh; absence of an edit not verified"
    else
      assert_ok "no product edit action targeted scripts/greet.sh"
    fi
    # Inspect every new track, including when allocation itself is wrong.
    while IFS= read -r new_track; do
      [ -n "$new_track" ] || continue
      track_root="$(checkpoint_dir 1)/fast-track-ai/tracks/$new_track"
      if [ -e "$track_root/assets" ] || [ -L "$track_root/assets" ]; then
        assert_bad "the compound-request track holds an assets entry"
      else
        assert_ok "the compound-request track has no assets entry"
      fi
      if grep -REiq 'assets/[^[:space:]]*report|report.*assets/' "$track_root"; then
        assert_bad "a track file mentions the report run as a track asset"
      else
        assert_ok "no track file mentions the report run as a track asset"
      fi
      if [ -e "$track_root/spec.md" ] || [ -L "$track_root/spec.md" ]; then
        assert_bad "compound-request advanced to spec.md in a single turn"
      else
        assert_ok "no compound-request spec.md"
      fi
    done < <(new_track_dirs)
    assert_intent_track || true
  fi
  verdict compound-request
}

scenario_artifact_threshold() {
  reset_assertions
  prepare_workspace artifact-threshold method
  if run_turns && require_turns 1 && assert_single_turn_checkpoints; then
    assert_staged_skill ft-intent
    assert_no_product_change 0 1
    assert_no_product_edit_action 1
    artifacts="$(changed_paths 0 1 | grep -E '^fast-track-ai/(assessments|decisions)/' || true)"
    if [ -n "$artifacts" ]; then
      assert_bad "a simple preference generated an assessment or decision: $artifacts"
    else
      assert_ok "no assessment or decision file added"
    fi
    if assert_intent_track; then
      intent="$(checkpoint_dir 1)/fast-track-ai/tracks/$track/intent.md"
      for heading in '### Verified by the agent' '### From the user' '### Proposed by the agent'; do
        if grep -Fxq "$heading" "$intent"; then assert_ok "intent contains $heading"; else assert_bad "intent lacks $heading"; fi
      done
    fi
  fi
  verdict artifact-threshold
}

for selected_scenario in $selected; do
  case " $continuation_scenarios " in
    *" $selected_scenario "*)
      ensure_compat
      if [ "$compat_result" != "supported" ]; then
        if [ "$compat_result" = "auth-failure" ]; then
          record_result "$selected_scenario" prerequisite-unavailable "headless continuation auth-failure: $compat_reason"
        else
          record_result "$selected_scenario" inconclusive "headless continuation $compat_result: $compat_reason"
        fi
        continue
      fi;;
  esac
  case "$selected_scenario" in
    compat) [ -n "$compat_result" ] || scenario_compat;;
    revision) scenario_revision;;
    approval) scenario_approval;;
    failed-validation) scenario_failed_validation;;
    material-change) scenario_material_change;;
    resume) scenario_resume;;
    direct-change) scenario_direct_change;;
    compound-request) scenario_compound_request;;
    artifact-threshold) scenario_artifact_threshold;;
  esac
done

finish
