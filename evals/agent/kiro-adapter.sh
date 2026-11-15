#!/usr/bin/env bash
# kiro-adapter.sh runs ordered user turns as headless Kiro sessions in one
# target workspace and records machine-readable evidence for every turn.
#
# Usage: kiro-adapter.sh --workspace DIR --turns-dir DIR --out DIR
#                        [--model MODEL] [--effort EFFORT] [--timeout SECONDS]
#
# Turns are the files turn-NN.txt in --turns-dir, run in lexical order. Turn 1
# starts a new session; every later turn resumes the previous turn's session
# with --resume-id. A turn that does not succeed stops the sequence.
#
# Output under --out (shared contract, see lib.sh):
#   turns.jsonl                one record per executed turn
#   turn-NN.events.jsonl       raw stream-json events from Kiro
#   turn-NN.stderr             Kiro stderr
#   turn-NN.actions.jsonl      normalized tool-call actions
#   checkpoints/turn-NN/       workspace snapshot after the turn (turn-00 = before turn 1)
#   checkpoints/turn-NN.manifest  sha256 manifest of that snapshot
# Snapshots exclude .git, .kiro, .claude, and .agents. Agent response text stays
# only in the raw events; no record field carries it.
#
# Every session runs in the isolated environment built by ftai_isolate (lib.sh):
# a private KIRO_HOME and a closed list of inherited variables, so the
# maintainer's steering, skills, agents, settings, and MCP servers under ~/.kiro
# are not loaded. The login lives in Kiro's data directory and is kept.
#
# Exit codes: 0 evidence recorded (inspect turns.jsonl for outcomes), 2 usage error.
set -euo pipefail

kiro_cli="${KIRO_CLI:-kiro-cli}"
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
adapter_init kiro-adapter.sh "$@"
ftai_isolate kiro
trap ftai_isolate_cleanup EXIT

# Tool calls are the `tool_call` session updates; a call ends at its first
# `completed` or `failed` update, which also gives the final status.
# Kiro 2.31 tool calls without a native `kind` are identified by
# `_meta.kiro.toolId`: `disclose_context` is a skill load (kind skill, path from
# the completed update's structured `rawOutput.item.id`, with its scope and
# source origin kept in `input.disclosure`; a failed or output-less disclosure
# has no path) and `fetch_cloud_config` is a read. Any other call without a kind
# stays `other`, which the turn coverage reports as incomplete.
normalize_actions() {
  local events_file="$1" turn="$2"
  jq -R -s -c --arg ws "$workspace_logical" --arg wsr "$workspace_real" --argjson turn "$turn" '
    def rel: if type == "string" then (ltrimstr("file://") | ltrimstr($wsr + "/") | ltrimstr($ws + "/") | ltrimstr("./")) else empty end;
    [split("\n")[] | select(length > 0) | (fromjson? // null)] | to_entries as $all
    | (reduce $all[] as $e ({};
        ($e.value) as $v
        | if ($v | type) == "object" and $v.type == "sessionUpdate" and $v.data.update.sessionUpdate == "tool_call_update"
          then ($v.data.update) as $uu
            | .[$uu.toolCallId] = ((.[$uu.toolCallId] // {})
                | (if $uu.status != null
                   then (.status = $uu.status
                         | if .endSeq == null and ($uu.status == "completed" or $uu.status == "failed") then .endSeq = $e.key else . end)
                   else . end)
                | (if ($uu.rawOutput | type) == "object" and ($uu.rawOutput.item | type) == "object" then .item = $uu.rawOutput.item else . end)
                | .output = ((.output // []) + [($uu.content // [])[]? | .content? | select(.type == "text") | .text | select(type == "string")])
                | (if ($uu._meta.kiro.disclosedContext | type) == "object" then .dc = $uu._meta.kiro.disclosedContext else . end))
          else . end)) as $st
    | $all[]
    | select(.value | type == "object" and .type == "sessionUpdate" and .data.update.sessionUpdate == "tool_call")
    | .key as $seq | .value.data.update as $u
    | ($u._meta.kiro.toolId // null) as $toolId
    | ($st[$u.toolCallId] // {}) as $s
    | ($s.item // null) as $item | ($s.dc // null) as $dc
    | ($item.type // $dc.type // null) as $ctxType
    | ($u.kind
        // (if $toolId == "disclose_context" then (if $ctxType == null or $ctxType == "skill" then "skill" else "other" end)
            elif $toolId == "fetch_cloud_config" then "read"
            else null end)
        // "other") as $kind
    | (($u.rawInput // {}) | if type == "object" then [.content?, .text?, .new_str?, .newStr?, .file_text?] | map(select(type == "string")) else [] end) as $written
    | ([ $item.id? | rel ] | if length > 0 then . else [ $dc.uri? | rel ] end) as $skillPaths
    | {
        turn: $turn,
        seq: $seq,
        endSeq: ($s.endSeq // null),
        toolCallId: $u.toolCallId,
        parent: null,
        kind: $kind,
        tool: ($u._meta.kiro.toolName // $toolId),
        paths: (if $kind == "skill" and $ctxType == "skill" then $skillPaths
                elif $kind == "skill" then []
                else ([($u.locations // [])[]?.path, (($u.content // []) | map(select(.type == "diff")) | .[].path), ($u.rawInput.path? // empty)] | map(rel) | unique) end),
        command: (if $u.kind == "execute" then ($u.rawInput.command // null) else null end),
        input: (if $kind == "skill" and ($u.rawInput | type) == "object"
                then $u.rawInput + {disclosure: {type: $ctxType, scope: ($item.scope? // null), origin: ($item.resource.source.origin? // $item.source.origin? // null)}}
                else ($u.rawInput // null) end),
        written: (if ($written | length) > 0 then $written else null end),
        output: ($s.output // []),
        status: ($s.status // null)
      }
  ' "$events_file"
}

turn_record() {
  local turn="$1" name="$2" outcome="$3" exit_code="$4" duration="$5" events_file="$6" actions_file="$7"
  jq -R -s -c --argjson turn "$turn" --arg checkpoint "$name" --arg outcome "$outcome" \
    --argjson exitCode "$exit_code" --argjson duration "$duration" --argjson actions "$(wc -l <"$actions_file" | tr -d ' ')" '
    [split("\n")[] | select(length > 0) | (fromjson? // "unparsed")] as $lines
    | [$lines[] | select(type == "object")] as $events
    | ($events | map(select(.type == "runFinished")) | last) as $finished
    | ([$events[] | select(.type == "metadata") | .data.meteringUsage[]?.value]) as $credits
    | {
        turn: $turn,
        harness: "kiro",
        checkpoint: $checkpoint,
        outcome: $outcome,
        exitCode: $exitCode,
        durationSeconds: $duration,
        sessionId: ([$events[] | .data.sessionId? // empty] | first // null),
        runStatus: ($finished.data.status // null),
        stopReason: ($finished.data.stopReason // null),
        ordered: (($events | any(.type == "runStarted")) and ($finished != null)),
        unparsedLines: ($lines | map(select(. == "unparsed")) | length),
        eventCount: ($events | length),
        actionCount: $actions,
        credits: (if ($credits | length) > 0 then ($credits | add) else null end),
        usage: null,
        observed: null
      }
  ' "$events_file"
}

classify() {
  local exit_code="$1" events_file="$2" stderr_file="$3" marker="$4"
  if [ -e "$marker" ]; then
    echo timeout
  elif [ "$exit_code" -eq 0 ] && jq -e -R -s '[split("\n")[] | select(length > 0) | (fromjson? // null)] | any(.[]; type == "object" and .type == "runFinished" and .data.status == "success")' "$events_file" >/dev/null 2>&1; then
    echo success
  elif grep -Eiq 'not logged in|login required|kiro-cli login|unauthori[sz]ed|authentication (failed|required)|token (has )?expired|expired token' "$stderr_file" 2>/dev/null; then
    # Only CLI stderr is inspected; agent response text never classifies a turn.
    echo auth-failure
  else
    echo error
  fi
}

: >"$out/turns.jsonl"
ftai_checkpoint turn-00
cd "$workspace_real"

session_id=""
turn=0
for turn_file in "$turns_dir"/turn-*.txt; do
  [ -f "$turn_file" ] || continue
  turn=$((turn + 1))
  name="$(printf 'turn-%02d' "$turn")"
  events_file="$out/$name.events.jsonl"
  stderr_file="$out/$name.stderr"
  actions_path="$out/$name.actions.jsonl"
  marker="$out/$name.timeout"

  args=(chat --output-format stream-json --trust-all-tools)
  [ -n "$model" ] && args+=(--model "$model")
  [ -n "$effort" ] && args+=(--effort "$effort")
  if [ "$turn" -gt 1 ]; then
    if [ -z "$session_id" ]; then
      jq -n -c --argjson turn "$turn" --arg checkpoint "$name" \
        '{turn: $turn, harness: "kiro", checkpoint: $checkpoint, outcome: "not-run", reason: "previous turn reported no session id"}' >>"$out/turns.jsonl"
      break
    fi
    args+=(--resume-id "$session_id")
  fi
  args+=("$(cat "$turn_file")")

  started="$(date +%s)"
  exit_code=0
  run_bounded "$timeout_seconds" "$events_file" "$stderr_file" "$marker" env -i "${ftai_env[@]}" "$kiro_cli" "${args[@]}" || exit_code=$?
  duration=$(( $(date +%s) - started ))

  ftai_checkpoint "$name"
  normalize_actions "$events_file" "$turn" >"$actions_path" 2>/dev/null || : >"$actions_path"
  outcome="$(classify "$exit_code" "$events_file" "$stderr_file" "$marker")"
  record="$(turn_record "$turn" "$name" "$outcome" "$exit_code" "$duration" "$events_file" "$actions_path")"
  action_loads="$(ftai_skill_loads "$actions_path" .kiro "$workspace_logical" "$workspace_real" 2>/dev/null || echo '[]')"
  record="$(printf '%s' "$record" | jq -c --argjson loads "$action_loads" '.skillLoads = $loads')"
  extra_reasons="$(jq -s -c '[ (map(select(.kind == "other")) | length) as $n | if $n > 0 then "unclassified-actions:\($n)" else empty end ]' "$actions_path" 2>/dev/null || echo '["actions-unreadable"]')"
  ftai_finalize_record "$record" "$actions_path" "$extra_reasons" >>"$out/turns.jsonl"

  [ "$outcome" = "success" ] || break
  session_id="$(printf '%s' "$record" | jq -r '.sessionId // empty')"
done

exit 0
