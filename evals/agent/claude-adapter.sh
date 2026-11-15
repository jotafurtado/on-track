#!/usr/bin/env bash
# claude-adapter.sh runs ordered user turns as headless Claude Code sessions in one
# target workspace and records machine-readable evidence for every turn.
#
# Usage: claude-adapter.sh --workspace DIR --turns-dir DIR --out DIR
#                          [--model MODEL] [--effort EFFORT] [--timeout SECONDS]
#
# Turns are the files turn-NN.txt in --turns-dir, run in lexical order. Turn 1
# starts a persisted session; every later turn resumes the session id reported by
# the previous turn with --resume. A turn that does not succeed stops the sequence.
#
# Invocation (per turn):
#   claude "<prompt>" -p --output-format stream-json --verbose
#          --permission-mode dontAsk --allowedTools "<tools>"
#          --setting-sources project,local --strict-mcp-config
#          --settings '{"autoMemoryEnabled":false,"sandbox":{"enabled":true,"autoAllowBashIfSandboxed":true,"allowUnsandboxedCommands":false}}'
#          [--model MODEL] [--effort EFFORT] [--resume SESSION]
# Shell commands run inside Claude Code's native sandbox, so writes outside the
# disposable workspace are denied.
#
# Every session runs in the isolated environment built by ftai_isolate (lib.sh):
# a closed list of inherited variables. The configuration directory stays the
# maintainer's, because the login is bound to it; --setting-sources project,local
# keeps user settings, user memory, and user-level skills out, --strict-mcp-config
# keeps MCP servers out, and auto memory is off (see evals.md).
#
# Output under --out (shared contract, see lib.sh):
#   turns.jsonl, turn-NN.events.jsonl, turn-NN.stderr, turn-NN.actions.jsonl,
#   checkpoints/turn-NN/ and checkpoints/turn-NN.manifest.
# Agent response text stays only in the raw events; no record field carries it.
#
# Exit codes: 0 evidence recorded (inspect turns.jsonl for outcomes), 2 usage error.
set -euo pipefail

claude_cli="${CLAUDE_CLI:-claude}"
# shellcheck source=lib.sh
. "$(cd "$(dirname "$0")" && pwd)/lib.sh"
adapter_init claude-adapter.sh "$@"
ftai_isolate claude

sandbox_settings='{"autoMemoryEnabled":false,"sandbox":{"enabled":true,"autoAllowBashIfSandboxed":true,"allowUnsandboxedCommands":false}}'
allowed_tools="Skill Read Write Edit MultiEdit NotebookEdit Bash Glob Grep Task Agent TodoWrite"

# Tool calls are `tool_use` content blocks of assistant events; a call ends at the
# `tool_result` block that references its id. Subagent calls carry the enclosing
# call id in `parent_tool_use_id`.
normalize_actions() {
  local events_file="$1" turn="$2"
  jq -R -s -c --arg ws "$workspace_logical" --arg wsr "$workspace_real" --argjson turn "$turn" '
    def rel: if type == "string" then (ltrimstr($wsr + "/") | ltrimstr($ws + "/") | ltrimstr("./")) else empty end;
    def kind_of: if . == "Read" or . == "Glob" or . == "Grep" then "read"
      elif . == "Edit" or . == "Write" or . == "MultiEdit" or . == "NotebookEdit" then "edit"
      elif . == "Bash" then "execute"
      elif . == "Task" or . == "Agent" then "agent"
      elif . == "Skill" then "skill"
      else "other" end;
    [split("\n")[] | select(length > 0) | (fromjson? // null)] | to_entries as $all
    | (reduce $all[] as $e ({};
        ($e.value) as $v
        | if ($v | type) == "object" and $v.type == "user" and (($v.message.content | type) == "array")
          then reduce ($v.message.content[] | select(type == "object" and .type == "tool_result")) as $r (.;
                 .[$r.tool_use_id] = {endSeq: $e.key, failed: ($r.is_error == true),
                   output: (if ($r.content | type) == "string" then [$r.content]
                            elif ($r.content | type) == "array" then [$r.content[]? | select(.type == "text") | .text | select(type == "string")]
                            else null end)})
          else . end)) as $res
    | $all[]
    | select(.value | type == "object" and .type == "assistant" and ((.message.content | type) == "array"))
    | .key as $seq | (.value.parent_tool_use_id // null) as $parent
    | .value.message.content[]
    | select(type == "object" and .type == "tool_use")
    | . as $u
    | ($u.name | kind_of) as $kind
    | ($u.input // {}) as $in
    | ([$in.content?, $in.new_string?, $in.new_source?] + (($in.edits // []) | if type == "array" then map(.new_string? // empty) else [] end) | map(select(type == "string"))) as $written
    | {
        turn: $turn,
        seq: $seq,
        endSeq: ($res[$u.id].endSeq // null),
        toolCallId: $u.id,
        parent: $parent,
        kind: $kind,
        tool: $u.name,
        paths: ([$in.file_path?, $in.notebook_path?, (if $kind == "read" then $in.path? else null end)] | map(select(type == "string") | rel) | unique),
        command: (if $kind == "execute" then ($in.command // null) else null end),
        input: $in,
        written: (if $kind == "edit" and ($written | length) > 0 then $written else null end),
        output: ($res[$u.id].output // null),
        status: (if $res[$u.id] == null then null elif $res[$u.id].failed then "failed" else "completed" end)
      }
  ' "$events_file"
}

# turn_record <turn> <checkpoint> <outcome> <exit> <duration> <events> <action-loads-json>
turn_record() {
  local turn="$1" name="$2" outcome="$3" exit_code="$4" duration="$5" events_file="$6" action_loads="$7"
  jq -R -s -c --argjson turn "$turn" --arg checkpoint "$name" --arg outcome "$outcome" \
    --argjson exitCode "$exit_code" --argjson duration "$duration" --argjson actionLoads "$action_loads" \
    --arg ws "$workspace_logical" --arg wsr "$workspace_real" '
    [split("\n")[] | select(length > 0) | (fromjson? // "unparsed")] as $lines
    | [$lines[] | select(type == "object")] as $events
    | ($events | map(select(.type == "system" and .subtype == "init")) | first) as $init
    | ($events | map(select(.type == "result")) | last) as $result
    | ([ $events[] | select(.type == "user") | .message.content? | select(type == "array") | .[]
         | select(type == "object" and .type == "text") | .text | select(type == "string")
         | capture("^Base directory for this skill: (?<p>[^\n]+)")? | .p ]) as $bases
    | ($bases | map(. as $p | ($p | split("/") | last) as $s
        | {skill: $s, path: $p, staged: ($p == ($wsr + "/.claude/skills/" + $s) or $p == ($ws + "/.claude/skills/" + $s))})) as $baseLoads
    | {
        turn: $turn,
        harness: "claude",
        checkpoint: $checkpoint,
        outcome: $outcome,
        exitCode: $exitCode,
        durationSeconds: $duration,
        sessionId: ($result.session_id // $init.session_id // null),
        runStatus: ($result.subtype // null),
        stopReason: ($result.stop_reason // null),
        ordered: ($init != null and $result != null),
        unparsedLines: ($lines | map(select(. == "unparsed")) | length),
        eventCount: ($events | length),
        actionCount: 0,
        credits: null,
        usage: (if $result == null then null else {
            inputTokens: ($result.usage.input_tokens // null),
            outputTokens: ($result.usage.output_tokens // null),
            cacheReadTokens: ($result.usage.cache_read_input_tokens // null),
            cacheCreationTokens: ($result.usage.cache_creation_input_tokens // null),
            costUsd: ($result.total_cost_usd // null)
          } end),
        observed: (if $init == null then null else {
            model: ($init.model // null),
            effort: null,
            permissionMode: ($init.permissionMode // null),
            cliVersion: ($init.claude_code_version // null)
          } end),
        skillLoads: (($baseLoads + $actionLoads) | unique)
      }
  ' "$events_file"
}

classify() {
  local exit_code="$1" events_file="$2" stderr_file="$3" marker="$4"
  if [ -e "$marker" ]; then
    echo timeout
  elif [ "$exit_code" -eq 0 ] && jq -e -R -s '[split("\n")[] | select(length > 0) | (fromjson? // null)] | any(.[]; type == "object" and .type == "result" and .subtype == "success" and .is_error == false)' "$events_file" >/dev/null 2>&1; then
    echo success
  elif jq -e -R -s '[split("\n")[] | select(length > 0) | (fromjson? // null)] | any(.[]; type == "object" and .type == "result" and (.api_error_status == 401 or .api_error_status == 403))' "$events_file" >/dev/null 2>&1 \
    || grep -Eiq 'not logged in|login required|claude auth login|unauthori[sz]ed|authentication (failed|required)|invalid api key' "$stderr_file" 2>/dev/null; then
    # Only the CLI's structured API status and stderr are inspected; agent response text never classifies a turn.
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

  args=("$(cat "$turn_file")" -p --output-format stream-json --verbose --permission-mode dontAsk
        --allowedTools "$allowed_tools" --setting-sources project,local --strict-mcp-config --settings "$sandbox_settings")
  [ -n "$model" ] && args+=(--model "$model")
  [ -n "$effort" ] && args+=(--effort "$effort")
  if [ "$turn" -gt 1 ]; then
    if [ -z "$session_id" ]; then
      jq -n -c --argjson turn "$turn" --arg checkpoint "$name" \
        '{turn: $turn, harness: "claude", checkpoint: $checkpoint, outcome: "not-run", reason: "previous turn reported no session id"}' >>"$out/turns.jsonl"
      break
    fi
    args+=(--resume "$session_id")
  fi

  started="$(date +%s)"
  exit_code=0
  run_bounded "$timeout_seconds" "$events_file" "$stderr_file" "$marker" env -i "${ftai_env[@]}" "$claude_cli" "${args[@]}" || exit_code=$?
  duration=$(( $(date +%s) - started ))

  ftai_checkpoint "$name"
  normalize_actions "$events_file" "$turn" >"$actions_path" 2>/dev/null || : >"$actions_path"
  outcome="$(classify "$exit_code" "$events_file" "$stderr_file" "$marker")"
  action_loads="$(ftai_skill_loads "$actions_path" .claude "$workspace_logical" "$workspace_real" 2>/dev/null || echo '[]')"
  record="$(turn_record "$turn" "$name" "$outcome" "$exit_code" "$duration" "$events_file" "$action_loads")"
  record="$(printf '%s' "$record" | jq -c --argjson n "$(wc -l <"$actions_path" | tr -d ' ')" '.actionCount = $n')"
  ftai_finalize_record "$record" "$actions_path" '[]' >>"$out/turns.jsonl"

  [ "$outcome" = "success" ] || break
  session_id="$(printf '%s' "$record" | jq -r '.sessionId // empty')"
done

exit 0
