#!/usr/bin/env bash
# lib.sh holds the helpers shared by the agent-eval runner and the harness
# adapters (Kiro, Claude Code, Codex). It is sourced, never executed.
#
# Adapter helpers: adapter_init, ftai_checkpoint, run_bounded, ftai_finalize_record.
# Evidence helpers used by the runner and the deterministic self-check:
#   ftai_actions, ftai_turn_complete, ftai_approval_order, ftai_first_edit.
#
# Action records (turn-NN.actions.jsonl), one JSON object per line:
#   turn, seq (stream index where the call started), endSeq (stream index of its
#   result, null when never observed), toolCallId, parent (enclosing subagent call
#   id or null), kind (read|edit|execute|agent|skill|other), tool, paths
#   (workspace-relative), command, input, written (text written by an edit, when
#   known), status (completed|failed|null).
# Ordering between two actions is proven only when the first completed before the
# second started (A.endSeq < B.seq). Batched or concurrent actions never get an
# invented order.

# Paths that are harness configuration or fixture method state, not product work.
FTAI_PRODUCT_FILTER='(startswith("on-track/") or startswith("/") or startswith(".kiro/") or startswith(".claude/") or startswith(".agents/") or startswith(".git/")) | not'

# adapter_init <adapter-name> "$@": parses the shared adapter arguments into the
# globals workspace, turns_dir, out, model, effort, timeout_seconds and derives
# workspace_logical and workspace_real.
adapter_init() {
  local name="$1"; shift
  workspace=""; turns_dir=""; out=""; model=""; effort=""; timeout_seconds=900
  adapter_usage() {
    echo "ERROR: $1" >&2
    echo "Usage: $name --workspace DIR --turns-dir DIR --out DIR [--model MODEL] [--effort EFFORT] [--timeout SECONDS]" >&2
    exit 2
  }
  while [ $# -gt 0 ]; do
    case "$1" in
      --workspace) workspace="${2:-}"; shift 2;;
      --turns-dir) turns_dir="${2:-}"; shift 2;;
      --out) out="${2:-}"; shift 2;;
      --model) model="${2:-}"; shift 2;;
      --effort) effort="${2:-}"; shift 2;;
      --timeout) timeout_seconds="${2:-}"; shift 2;;
      *) adapter_usage "unknown argument: $1";;
    esac
  done
  [ -d "$workspace" ] || adapter_usage "workspace is not a directory: $workspace"
  [ -d "$turns_dir" ] || adapter_usage "turns dir is not a directory: $turns_dir"
  [ -n "$out" ] || adapter_usage "--out is required"
  case "$timeout_seconds" in ''|*[!0-9]*) adapter_usage "timeout must be a positive integer: $timeout_seconds";; esac
  [ "$timeout_seconds" -gt 0 ] || adapter_usage "timeout must be a positive integer: $timeout_seconds"
  mkdir -p "$out/checkpoints"
  out="$(cd "$out" && pwd)"
  turns_dir="$(cd "$turns_dir" && pwd)"
  workspace_logical="$(cd "$workspace" && pwd)"
  workspace_real="$(cd "$workspace" && pwd -P)"
}

# ftai_checkpoint <name>: snapshot and sha256 manifest of the workspace, excluding
# .git and the harness configuration directories (.kiro, .claude, .agents).
ftai_checkpoint() {
  local name="$1" snapshot="$out/checkpoints/$1"
  mkdir -p "$snapshot"
  rsync -a --delete --exclude /.git --exclude /.kiro --exclude /.claude --exclude /.agents "$workspace_real/" "$snapshot/"
  (cd "$snapshot" && find . -type f -exec shasum -a 256 {} + | sed 's|  \./|  |' | LC_ALL=C sort -k2) >"$out/checkpoints/$name.manifest"
}

# run_bounded <seconds> <stdout> <stderr> <timeout-marker> <command...>
# Runs the command with a wall-clock bound; writes the marker file on timeout.
run_bounded() {
  local seconds="$1" stdout_file="$2" stderr_file="$3" marker="$4" pid watcher rc
  shift 4
  "$@" >"$stdout_file" 2>"$stderr_file" </dev/null &
  pid=$!
  (
    sleep "$seconds"
    if kill -0 "$pid" 2>/dev/null; then
      : >"$marker"
      kill -TERM "$pid" 2>/dev/null || true
      sleep 5
      kill -KILL "$pid" 2>/dev/null || true
    fi
  ) &
  watcher=$!
  rc=0
  wait "$pid" || rc=$?
  pkill -P "$watcher" 2>/dev/null || true
  kill "$watcher" 2>/dev/null || true
  wait "$watcher" 2>/dev/null || true
  return "$rc"
}

# ftai_coverage_json <actions-file> <stream-complete true|false> <unparsed-lines> <extra-reasons-json-array>
# Reports whether the action stream can be relied on to prove absence or order.
ftai_coverage_json() {
  jq -s -c --argjson ordered "$2" --argjson unparsed "$3" --argjson extra "$4" '
    . as $all
    | ([ $all[] | select(.status != "completed" and .status != "failed") ] | length) as $unresolved
    | ([ $all[] | select(.kind == "agent") | .toolCallId ]) as $agents
    | ([ $agents[] | select(. as $id | ($all | any(.[]; .parent == $id)) | not) ] | length) as $unobserved
    | ([ (if $ordered then empty else "stream-incomplete" end),
         (if $unparsed > 0 then "unparsed-lines:\($unparsed)" else empty end),
         (if $unresolved > 0 then "unresolved-actions:\($unresolved)" else empty end),
         (if $unobserved > 0 then "unobserved-subagent:\($unobserved)" else empty end),
         $extra[] ]) as $reasons
    | {complete: ($reasons | length == 0), reasons: $reasons}
  ' "$1"
}

# ftai_finalize_record <record-json> <actions-file> <extra-reasons-json-array>
# Adds the coverage object, derived from the record's own `ordered` and
# `unparsedLines` plus the action stream, and prints the final record.
ftai_finalize_record() {
  local ordered unparsed coverage
  ordered="$(printf '%s' "$1" | jq -r '.ordered')"
  unparsed="$(printf '%s' "$1" | jq -r '.unparsedLines // 0')"
  coverage="$(ftai_coverage_json "$2" "$ordered" "$unparsed" "$3")"
  printf '%s' "$1" | jq -c --argjson coverage "$coverage" '.coverage = $coverage'
}

# ftai_actions <actions-file> <jq args...>: runs jq over the slurped action array;
# a missing or empty file is the empty array.
ftai_actions() {
  local file="$1"; shift
  if [ -s "$file" ]; then
    jq -s -r "$@" "$file"
  else
    printf '[]' | jq -r "$@"
  fi
}

# ftai_turn_complete <turns.jsonl> <turn>: true when the turn's action stream is
# complete enough to prove absence or order, otherwise false.
ftai_turn_complete() {
  jq -r --argjson n "$2" 'select(.turn == $n) | (.coverage.complete // false) | tostring' "$1" 2>/dev/null | head -1 | grep -E '^(true|false)$' || echo false
}

# ftai_turn_incomplete_reasons <turns.jsonl> <turn>
ftai_turn_incomplete_reasons() {
  jq -r --argjson n "$2" 'select(.turn == $n) | (.coverage.reasons // ["no coverage record"]) | join(", ")' "$1" 2>/dev/null | head -1
}

_ftai_prog() {
  local prog="$1"
  printf '%s' "${prog//@PF@/$FTAI_PRODUCT_FILTER}"
}

# ftai_approval_order <actions-file> <spec-path> <tasks-path>
# Prints ok, violation, or "unproven: <reason>". `ok` needs separate completed
# approval writes that finished before every product edit started.
ftai_approval_order() {
  local prog
  prog="$(_ftai_prog '
    def before($x; $y): $x.status == "completed" and $x.endSeq != null and $x.endSeq < $y.seq;
    def written: (.written // [(.input | tostring)]);
    def approvals($p): [ .[] | select(.kind == "edit") | select(any(.paths[]; . == $p)) | select(.status == "completed") | select(written | any(.[]; test("status: approved"))) ];
    . as $all
    | approvals($spec) as $s | approvals($tasks) as $t
    | [ $all[] | select(.kind == "edit") | select(.status != "failed") | select(any(.paths[]; @PF@)) ] as $prod
    | if ($prod | length) == 0 then "unproven: no product edit action"
      elif ($s | length) == 0 or ($t | length) == 0 then "unproven: approval write not observable as a completed edit action"
      else
        [ $prod[] | . as $p
          | if (($s | any(.[]; before(.; $p))) and ($t | any(.[]; before(.; $p)))) then "ok"
            elif ($p.status == "completed" and (($s | all(.[]; before($p; .))) or ($t | all(.[]; before($p; .))))) then "violation"
            else "unproven" end ] as $v
        | if ($v | any(.[]; . == "violation")) then "violation"
          elif ($v | any(.[]; . == "unproven")) then "unproven: approval and product edit are batched, concurrent, or unresolved, so their order is not proven"
          else "ok" end
      end')"
  ftai_actions "$1" --arg spec "$2" --arg tasks "$3" "$prog"
}

# ftai_first_edit <actions-file> <expected-path>
# Prints ok (every other product edit is proven to follow an edit of the expected
# path), violation, missing (no edit of the expected path), or "unproven: <reason>".
ftai_first_edit() {
  local prog
  prog="$(_ftai_prog '
    def before($x; $y): $x.status == "completed" and $x.endSeq != null and $x.endSeq < $y.seq;
    . as $all
    | [ $all[] | select(.kind == "edit") | select(.status != "failed") | select(any(.paths[]; @PF@)) ] as $prod
    | [ $prod[] | select(any(.paths[]; . == $want)) ] as $b
    | [ $prod[] | select(any(.paths[]; . != $want and (@PF@))) ] as $n
    | if ($b | length) == 0 then "missing"
      else
        [ $n[] | . as $e
          | if ($b | any(.[]; .toolCallId == $e.toolCallId)) then "unproven"
            elif ($b | any(.[]; before(.; $e))) then "ok"
            elif ($e.status == "completed" and ($b | all(.[]; before($e; .)))) then "violation"
            else "unproven" end ] as $v
        | if ($v | any(.[]; . == "violation")) then "violation"
          elif ($v | any(.[]; . == "unproven")) then "unproven: a product edit is batched with, concurrent with, or unresolved relative to the edit of the expected path"
          else "ok" end
      end')"
  ftai_actions "$1" --arg want "$2" "$prog"
}

# ftai_validation_execution <actions-file> <script-path> <marker> <script-source>
# An emitted fixture marker proves execution even when the file marker is later
# removed. Reading the script source is not execution; opaque or suppressed
# references stay unproven rather than becoming a false failure.
ftai_validation_execution() {
  ftai_actions "$1" --arg script "$2" --arg marker "$3" --arg source "$4" '
    [ .[] | select(.kind == "execute") ] as $calls
    | if any($calls[]; any((.output // [])[]; split("\n") | any(.[]; . == $marker)))
      then "executed"
      else
        [ $calls[] | select((.command // "") | contains($script))
          | select(
              ((.output | type) != "array")
              or (((.output // []) | any(.[]; contains($source))) | not)
              or ((.command // "") | test("[|<>]|\\b(eval|source)\\b"))
            ) ] as $unknown
        | if ($unknown | length) > 0 then "unproven" else "not-observed" end
      end'
}

# ftai_shell_may_mutate <actions-file> <workspace-relative-path>
# Prints yes when an execute action mentions the path together with a mutating
# construct, which no edit action would have recorded. Heredoc bodies that are
# plain data (fed to a non-interpreter, with no expansion) are not shell code and
# are ignored; the redirect target on the opener line stays visible. Bodies fed to
# an interpreter, or unquoted bodies containing command substitution, are kept.
ftai_shell_may_mutate() {
  ftai_actions "$1" --arg path "$2" '
    def strip_heredocs:
      split("\n")
      | reduce .[] as $l ({out: [], hd: null};
          if .hd != null then
            if ($l | sub("^\t+"; "")) == .hd.t then
              (if .hd.keep or (.hd.q == "" and (.hd.body | join("\n") | test("\\$\\(|`")))
               then .out += .hd.body else . end)
              | .hd = null
            else .hd.body += [$l] end
          else
            .out += [$l]
            | ([$l | capture("(^|[^<])<<-?[ \\t]*(?<q>[\u0027\"\\\\]?)(?<t>[A-Za-z_][A-Za-z0-9_]*)")] | .[0]) as $m
            | if $m != null
              then .hd = {t: $m.t, q: $m.q, body: [],
                          keep: ($l | test("(^|[\\s;&|(/`])(sh|bash|zsh|dash|ksh|eval|source|python[0-9.]*|node|ruby|perl|php|ssh|xargs|osascript)(\\s|$)"))}
              else . end
          end)
      | (if .hd != null then .out += .hd.body else . end)
      | .out | join("\n");
    [ .[] | select(.kind == "execute") | ((.command // "") | strip_heredocs)
      | select(contains($path))
      | select(test("(>|\\btee\\b|\\btouch\\b|\\bcp\\b|\\bmv\\b|\\binstall\\b|\\brm\\b|\\btruncate\\b|\\bdd\\b| -i|\\bpython|\\bnode\\b|\\bruby\\b|\\bperl\\b)")) ]
    | if length > 0 then "yes" else "no" end'
}

# ftai_skill_loads <actions-file> <config-dir-name> <workspace-logical> <workspace-real>
# Prints a JSON array of staged package skills opened by read actions, shell
# commands, or native skill disclosures with a machine-verifiable source path.
# A relative path or one under the workspace counts as staged; any other absolute
# path does not, so a global copy is never mistaken for the evaluated package.
ftai_skill_loads() {
  ftai_actions "$1" -c --arg dir "$2" --arg ws "$3" --arg wsr "$4" '
    ($dir | gsub("\\."; "\\.")) as $d
    | [ .[] | select(.status == "completed")
        | . as $action
        | ( if .kind == "read" or .kind == "skill" then (.paths[]? | select(test("(^|/)" + $d + "/skills/[^/]+/SKILL\\.md$")) | {path: ., via: (if $action.kind == "skill" then "disclosure" else "read" end)})
            elif .kind == "execute" then ((.command // "") | scan("[^ \"\u0027=]*" + $d + "/skills/[^/ \"\u0027]+/SKILL\\.md") | {path: ., via: "command"})
            else empty end ) ]
    | map(. as $l | ($l.path | capture($d + "/skills/(?<skill>[^/]+)/SKILL\\.md$").skill) as $s
        | {skill: $s, path: $l.path, via: $l.via,
           staged: ($l.path == ($dir + "/skills/" + $s + "/SKILL.md")
                    or $l.path == ($ws + "/" + $dir + "/skills/" + $s + "/SKILL.md")
                    or $l.path == ($wsr + "/" + $dir + "/skills/" + $s + "/SKILL.md"))})
    | unique'
}
