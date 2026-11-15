#!/usr/bin/env bash
# codex-adapter.sh runs ordered user turns as headless Codex sessions in one
# target workspace and records machine-readable evidence for every turn.
#
# Usage: codex-adapter.sh --workspace DIR --turns-dir DIR --out DIR
#                         [--model MODEL] [--effort EFFORT] [--timeout SECONDS]
#
# Turns are the files turn-NN.txt in --turns-dir, run in lexical order. Turn 1
# starts a persisted thread with `codex exec --json`; every later turn runs
# `codex exec resume <thread-id> --json` with the thread id reported by turn 1.
# A turn that does not succeed stops the sequence.
#
# Invocation (per turn):
#   codex exec --json -C <workspace> -c 'sandbox_mode="workspace-write"'
#              -c 'approval_policy="never"' -c 'features.apps=false' [-m MODEL] [-c 'model_reasoning_effort="E"'] "<prompt>"
#   codex exec resume <thread-id> --json -c ... [-m MODEL] [-c ...] "<prompt>"
# Sessions are persisted: no --ephemeral, no --last, no sandbox bypass. Shell
# commands run inside Codex's workspace-write sandbox.
#
# Every session runs in the isolated environment built by ftai_isolate (lib.sh):
# a private HOME and CODEX_HOME that hold only a link to the maintainer's
# auth.json, a closed list of inherited variables, and account-level apps
# disabled. The maintainer's config.toml, AGENTS.md, hooks, and user-level skills
# are not loaded (see evals.md).
#
# Native stdout events omit patch content, so file-change detail is read from the
# thread's local rollout file under the private CODEX_HOME/sessions (read-only,
# outside the workspace). When it cannot be found, approval content stays unproven.
#
# Output under --out (shared contract, see lib.sh):
#   turns.jsonl, turn-NN.events.jsonl, turn-NN.stderr, turn-NN.actions.jsonl,
#   turn-NN.rollout.jsonl (this turn's slice of the local session file),
#   checkpoints/turn-NN/ and checkpoints/turn-NN.manifest.
# Agent response text stays only in the raw events; no record field carries it.
#
# Exit codes: 0 evidence recorded (inspect turns.jsonl for outcomes), 2 usage error.
set -euo pipefail

codex_cli="${CODEX_CLI:-codex}"
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
adapter_init codex-adapter.sh "$@"
ftai_isolate codex
trap ftai_isolate_cleanup EXIT
codex_home="$ftai_iso_home/.codex"

cli_version="$("$codex_cli" --version 2>/dev/null | head -1 || true)"

# find_rollout <thread-id>: the local session file of a thread, or nothing.
find_rollout() {
  find "$codex_home/sessions" -type f -name "rollout-*-$1.jsonl" 2>/dev/null | head -1 || true
}

# rollout_changes <rollout-slice>: FileChange items recorded by Codex for the turn,
# in order, with the patch content that stdout events omit.
rollout_changes() {
  if [ -s "$1" ]; then
    jq -s -c '[ .[] | select(type == "object" and .type == "event_msg" and .payload.type == "item_completed" and .payload.item.type == "FileChange")
                | .payload.item | {status: .status, changes: .changes} ]' "$1" 2>/dev/null || echo '[]'
  else
    echo '[]'
  fi
}

# normalize_actions <events> <turn> <rollout-changes-json>
# Actions are item.started/item.completed pairs of command_execution, file_change,
# and other tool items. seq is the stream index where an item first appeared and
# endSeq the index of its item.completed event.
normalize_actions() {
  local events_file="$1" turn="$2" rollout="$3"
  jq -R -s -c --arg ws "$workspace_logical" --arg wsr "$workspace_real" --argjson turn "$turn" --argjson rollout "$rollout" '
    def rel: if type == "string" then (ltrimstr($wsr + "/") | ltrimstr($ws + "/") | ltrimstr("./")) else empty end;
    def kind_of: if . == "command_execution" then "execute"
      elif . == "file_change" then "edit"
      elif . == "collab_tool_call" then "agent"
      else "other" end;
    def status_of: if . == "completed" then "completed" elif . == "failed" or . == "declined" then "failed" else null end;
    def written_of($detail):
      if $detail == null then null
      else ([ ($detail.changes // {}) | to_entries[] | .value
              | if .type == "add" then (.content // empty)
                elif .type == "update" then ((.unified_diff // "") | split("\n") | map(select(startswith("+") and (startswith("+++") | not)) | ltrimstr("+")) | join("\n"))
                else empty end ]
            | if length > 0 then . else null end) end;
    [split("\n")[] | select(length > 0) | (fromjson? // null)] | to_entries as $all
    | (reduce $all[] as $e ({};
        ($e.value) as $v
        | if ($v | type) == "object" and ($v.type == "item.started" or $v.type == "item.completed")
             and ($v.item.type | IN("command_execution", "file_change", "mcp_tool_call", "collab_tool_call", "web_search"))
          then .[$v.item.id] |= ((. // {first: $e.key}) | .item = $v.item | if $v.type == "item.completed" then .endSeq = $e.key else . end)
          else . end)) as $items
    | ($items | to_entries | sort_by(.value.first)) as $list
    | ($list | map(select(.value.item.type == "file_change") | .key)) as $patchIds
    | ($rollout | length == ($patchIds | length)) as $detailMatches
    | $list[]
    | .key as $id | .value as $v | $v.item as $item
    | ($patchIds | index($id)) as $patchIndex
    | (if $detailMatches and $patchIndex != null then $rollout[$patchIndex] else null end) as $detail
    | {
        turn: $turn,
        seq: $v.first,
        endSeq: ($v.endSeq // null),
        toolCallId: $id,
        parent: null,
        kind: ($item.type | kind_of),
        tool: $item.type,
        paths: (if $item.type == "file_change" then ([($item.changes // [])[]?.path] | map(rel) | unique) else [] end),
        command: (if $item.type == "command_execution" then ($item.command // null) else null end),
        input: (if $item.type == "file_change" then {changes: ($item.changes // [])} elif $item.type == "command_execution" then {command: ($item.command // null), exitCode: ($item.exit_code // null)} else $item end),
        written: (if $item.type == "file_change" then written_of($detail) else null end),
        output: (if $item.type == "command_execution" and ($item.aggregated_output | type) == "string" then [$item.aggregated_output] else null end),
        status: ($item.status | status_of)
      }
  ' "$events_file"
}

# turn_record <turn> <checkpoint> <outcome> <exit> <duration> <events> <rollout-slice> <rollout-found true|false>
turn_record() {
  local turn="$1" name="$2" outcome="$3" exit_code="$4" duration="$5" events_file="$6" rollout_slice="$7" found="$8"
  local observed='null'
  if [ -s "$rollout_slice" ]; then
    observed="$(jq -s -c --arg cli "$cli_version" '
      [ .[] | select(type == "object" and .type == "turn_context") | .payload ] | last
      | if . == null then null else {
          model: (.model // null),
          effort: (.effort // null),
          approvalPolicy: (.approval_policy // null),
          sandbox: (.sandbox_policy.type // .permission_profile.type // null),
          cliVersion: $cli
        } end' "$rollout_slice" 2>/dev/null || echo null)"
  fi
  jq -R -s -c --argjson turn "$turn" --arg checkpoint "$name" --arg outcome "$outcome" \
    --argjson exitCode "$exit_code" --argjson duration "$duration" --argjson observed "$observed" --argjson found "$found" '
    [split("\n")[] | select(length > 0) | (fromjson? // "unparsed")] as $lines
    | [$lines[] | select(type == "object")] as $events
    | ($events | map(select(.type == "turn.completed")) | last) as $completed
    | ($events | map(select(.type == "thread.started")) | first) as $started
    | {
        turn: $turn,
        harness: "codex",
        checkpoint: $checkpoint,
        outcome: $outcome,
        exitCode: $exitCode,
        durationSeconds: $duration,
        sessionId: ($started.thread_id // null),
        runStatus: (if $completed != null then "completed" elif any($events[]; .type == "turn.failed") then "failed" else null end),
        stopReason: null,
        ordered: ($started != null and $completed != null),
        unparsedLines: ($lines | map(select(. == "unparsed")) | length),
        eventCount: ($events | length),
        actionCount: 0,
        credits: null,
        usage: (if $completed == null then null else {
            inputTokens: ($completed.usage.input_tokens // null),
            outputTokens: ($completed.usage.output_tokens // null),
            cacheReadTokens: ($completed.usage.cached_input_tokens // null),
            reasoningTokens: ($completed.usage.reasoning_output_tokens // null),
            costUsd: null
          } end),
        observed: $observed,
        localEvidence: (if $found then "rollout" else "unavailable" end)
      }
  ' "$events_file"
}

classify() {
  local exit_code="$1" events_file="$2" stderr_file="$3" marker="$4"
  if [ -e "$marker" ]; then
    echo timeout
  elif [ "$exit_code" -eq 0 ] && jq -e -R -s '[split("\n")[] | select(length > 0) | (fromjson? // null)] | (any(.[]; type == "object" and .type == "turn.completed")) and (any(.[]; type == "object" and .type == "turn.failed") | not)' "$events_file" >/dev/null 2>&1; then
    echo success
  elif jq -e -R -s '[split("\n")[] | select(length > 0) | (fromjson? // null)] | any(.[]; type == "object" and (.type == "error" or .type == "turn.failed") and ((.message // .error.message // "") | test("401|unauthori[sz]ed|not logged in|log ?in required|authentication"; "i")))' "$events_file" >/dev/null 2>&1 \
    || grep -Eiq 'not logged in|login required|codex login|unauthori[sz]ed|authentication (failed|required)' "$stderr_file" 2>/dev/null; then
    # Only the CLI's structured error events and stderr are inspected; agent response text never classifies a turn.
    echo auth-failure
  else
    echo error
  fi
}

: >"$out/turns.jsonl"
ftai_checkpoint turn-00
cd "$workspace_real"

thread_id=""
turn=0
for turn_file in "$turns_dir"/turn-*.txt; do
  [ -f "$turn_file" ] || continue
  turn=$((turn + 1))
  name="$(printf 'turn-%02d' "$turn")"
  events_file="$out/$name.events.jsonl"
  stderr_file="$out/$name.stderr"
  actions_path="$out/$name.actions.jsonl"
  rollout_slice="$out/$name.rollout.jsonl"
  marker="$out/$name.timeout"

  config_args=(-c 'sandbox_mode="workspace-write"' -c 'approval_policy="never"' -c 'features.apps=false')
  [ -n "$model" ] && config_args+=(-m "$model")
  [ -n "$effort" ] && config_args+=(-c "model_reasoning_effort=\"$effort\"")
  rollout_offset=0
  if [ "$turn" -eq 1 ]; then
    args=(exec --json -C "$workspace_real" "${config_args[@]}")
  else
    if [ -z "$thread_id" ]; then
      jq -n -c --argjson turn "$turn" --arg checkpoint "$name" \
        '{turn: $turn, harness: "codex", checkpoint: $checkpoint, outcome: "not-run", reason: "previous turn reported no thread id"}' >>"$out/turns.jsonl"
      break
    fi
    previous_rollout="$(find_rollout "$thread_id")"
    [ -z "$previous_rollout" ] || rollout_offset="$(wc -l <"$previous_rollout" | tr -d ' ')"
    args=(exec resume "$thread_id" --json "${config_args[@]}")
  fi
  args+=("$(cat "$turn_file")")

  started="$(date +%s)"
  exit_code=0
  run_bounded "$timeout_seconds" "$events_file" "$stderr_file" "$marker" env -i "${ftai_env[@]}" "$codex_cli" "${args[@]}" || exit_code=$?
  duration=$(( $(date +%s) - started ))

  ftai_checkpoint "$name"
  outcome="$(classify "$exit_code" "$events_file" "$stderr_file" "$marker")"
  turn_thread="$(jq -R -s -r '[split("\n")[] | select(length > 0) | (fromjson? // null) | select(type == "object" and .type == "thread.started") | .thread_id] | first // empty' "$events_file" 2>/dev/null || true)"
  rollout_found=false
  : >"$rollout_slice"
  if [ -n "$turn_thread" ]; then
    rollout_file="$(find_rollout "$turn_thread")"
    if [ -n "$rollout_file" ]; then
      rollout_found=true
      tail -n +"$((rollout_offset + 1))" "$rollout_file" >"$rollout_slice"
    fi
  fi
  normalize_actions "$events_file" "$turn" "$(rollout_changes "$rollout_slice")" >"$actions_path" 2>/dev/null || : >"$actions_path"
  record="$(turn_record "$turn" "$name" "$outcome" "$exit_code" "$duration" "$events_file" "$rollout_slice" "$rollout_found")"
  record="$(printf '%s' "$record" | jq -c --argjson n "$(wc -l <"$actions_path" | tr -d ' ')" '.actionCount = $n')"
  action_loads="$(ftai_skill_loads "$actions_path" .agents "$workspace_logical" "$workspace_real" 2>/dev/null || echo '[]')"
  record="$(printf '%s' "$record" | jq -c --argjson loads "$action_loads" '.skillLoads = $loads')"
  extra_reasons="$(jq -s -c '[ (map(select(.kind == "other")) | length) as $n | if $n > 0 then "unclassified-actions:\($n)" else empty end ]' "$actions_path" 2>/dev/null || echo '[]')"
  ftai_finalize_record "$record" "$actions_path" "$extra_reasons" >>"$out/turns.jsonl"

  [ "$outcome" = "success" ] || break
  thread_id="$(printf '%s' "$record" | jq -r '.sessionId // empty')"
done

exit 0
