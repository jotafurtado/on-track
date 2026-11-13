#!/usr/bin/env bash
# on-track-gate.sh validates track structure and, in completion mode, approval and task closure.
# Usage: on-track-gate.sh --track NNN-slug [--root DIR] [--mode structure|completion]
# Frontmatter of intent.md, spec.md, and tasks.md uses a canonical subset, not general YAML:
# line 1 is exactly `---`, the next line that is exactly `---` closes the block, each non-blank
# line between them is one `key: value` field (key matches [a-z][a-z0-9_]*, value may be empty,
# a flow list [a, b] is one value), and no key appears twice. Fields are read only from that block.
set -euo pipefail

track=""
root="."
mode="completion"
while [ $# -gt 0 ]; do
  case "$1" in
    --track) track="${2:-}"; shift 2;;
    --root) root="${2:-.}"; shift 2;;
    --mode) mode="${2:-}"; shift 2;;
    *) echo "FAIL: unknown argument: $1"; exit 1;;
  esac
done
[ -n "$track" ] || { echo "FAIL: pass --track NNN-slug"; exit 1; }
case "$mode" in
  structure|completion) ;;
  *) echo "FAIL: unknown mode '$mode'; accepted modes are structure and completion"; exit 1;;
esac

frontmatter_field() {
  awk -v key="$2" 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { exit } index($0, key ":") == 1 {sub(/^[^:]+:[[:space:]]*/, ""); print; exit}' "$1"
}

frontmatter_violation() {
  awk '
    NR == 1 { if ($0 != "---") exit; open=1; next }
    $0 == "---" { closed=1; exit }
    $0 ~ /^[[:space:]]*$/ { next }
    $0 !~ /^[a-z][a-z0-9_]*:([[:space:]].*)?$/ { print "frontmatter line " NR " is not a key: value field"; bad=1; exit }
    {
      key=$0
      sub(/:.*/, "", key)
      if (seen[key]++) { print "duplicate frontmatter field " key; bad=1; exit }
    }
    END { if (open && !closed && !bad) print "frontmatter not closed" }
  ' "$1"
}

require_frontmatter() {
  local violation
  violation="$(frontmatter_violation "$1")"
  [ -z "$violation" ] || { echo "FAIL: ${1#"$root"/} $violation"; exit 1; }
}

require_approved() {
  local file="$1"
  local label="$2"
  [ -f "$file" ] || { echo "FAIL: $track missing $label"; exit 1; }
  local status
  status="$(frontmatter_field "$file" status)"
  [ "$status" = "approved" ] || { echo "FAIL: $label status must be approved, got ${status:-missing}"; exit 1; }
}

require_closed_tasks() {
  local file="$1"
  local open
  open="$(grep -c -- "^- \[ \] " "$file" || true)"
  [ "$open" = "0" ] || { echo "FAIL: $open open task(s) in ${file#"$root"/}"; exit 1; }
}

base="$root/on-track/tracks/$track"
intent="$base/intent.md"
[ -e "$intent" ] || { echo "FAIL: $track missing intent.md"; exit 1; }
[ -f "$intent" ] || { echo "FAIL: $track intent.md must be a file"; exit 1; }
require_frontmatter "$intent"
id="$(frontmatter_field "$intent" id)"
[ -n "$id" ] || { echo "FAIL: intent without id"; exit 1; }
[ "$id" = "$track" ] || { echo "FAIL: intent id mismatch: $id (expected $track)"; exit 1; }

hidden=0
for entry in "$base"/.[!.]* "$base"/..?*; do
  [ -e "$entry" ] || [ -L "$entry" ] || continue
  echo "FAIL: $track hidden root entry: $(basename "$entry")"
  hidden=1
done
[ "$hidden" = "0" ] || exit 1

allowed="intent.md spec.md tasks.md assets"
offenders=""
for entry in "$base"/*; do
  [ -e "$entry" ] || continue
  name="$(basename "$entry")"
  ok=0
  for allowed_name in $allowed; do
    if [ "$name" = "$allowed_name" ]; then ok=1; break; fi
  done
  if [ "$ok" = "0" ]; then offenders="$offenders $name"; fi
done
[ -z "$offenders" ] || { echo "FAIL: loose files outside assets/:$offenders"; exit 1; }

for file_name in spec.md tasks.md; do
  if [ -e "$base/$file_name" ] && [ ! -f "$base/$file_name" ]; then
    echo "FAIL: $track $file_name must be a file"
    exit 1
  fi
done
for directory_name in assets; do
  if [ -e "$base/$directory_name" ] && [ ! -d "$base/$directory_name" ]; then
    echo "FAIL: $track $directory_name must be a directory"
    exit 1
  fi
done

spec="$base/spec.md"
tasks="$base/tasks.md"
[ -f "$spec" ] || { echo "FAIL: $track missing spec.md"; exit 1; }
[ -f "$tasks" ] || { echo "FAIL: $track missing tasks.md"; exit 1; }
require_frontmatter "$spec"
require_frontmatter "$tasks"

awk -v file="${spec#"$root"/}" '
  function report(message) { print "FAIL: " file ": " message; failed=1 }
  function finish_phase() {
    if (!done_field) report(name " missing or empty Done:")
    if (!files_field) report(name " missing or empty Files:")
    if (!accept_field) report(name " missing or empty Accept:")
  }
  /^### Phase([[:space:]]|$)/ {
    if (phase) finish_phase()
    phase_count++
    phase=1
    name=$0
    sub(/^### /, "", name)
    done_field=files_field=accept_field=0
    next
  }
  /^##/ {
    if (phase) finish_phase()
    phase=0
    next
  }
  phase {
    if ($0 ~ /^Done:[[:space:]]*[^[:space:]]/) done_field=1
    if ($0 ~ /^Files:[[:space:]]*[^[:space:]]/) files_field=1
    if ($0 ~ /^Accept:[[:space:]]*[^[:space:]]/) accept_field=1
  }
  END {
    if (phase) finish_phase()
    if (!phase_count) report("spec has no ### Phase section")
    if (failed) exit 1
  }
' "$spec" || exit 1

awk -v file="${tasks#"$root"/}" '
  function report(message) { print "FAIL: " file ": " message; failed=1 }
  function trim(value) { sub(/^[[:space:]]+/, "", value); sub(/[[:space:]]+$/, "", value); return value }
  function value_for(line, label, other, value, start, stop) {
    start=index(line, label ":")
    if (!start) return ""
    value=substr(line, start+length(label)+1)
    stop=index(value, other ":")
    if (stop) value=substr(value, 1, stop-1)
    return trim(value)
  }
  function visit(node,    dep, next_node, path, i) {
    state[node]=1
    stack[++depth]=node
    for (dep in dependencies) {
      split(dep, edge, SUBSEP)
      if (edge[1] != node) continue
      next_node=edge[2]
      if (state[next_node] == 1) {
        path=""
        for (i=1; i<=depth; i++) {
          if (stack[i] == next_node || path != "") path=path (path == "" ? "" : " -> ") stack[i]
        }
        report("dependency cycle involving " path " -> " next_node)
      } else if (state[next_node] == 0) visit(next_node)
    }
    depth--
    state[node]=2
  }
  /^## Group[[:space:]]+/ {
    header_count++
    current=$0
    sub(/^## Group[[:space:]]+/, "", current)
    if (match(current, /[[:space:]]+\(depends:[^)]*\)[[:space:]]*$/)) {
      annotation=substr(current, RSTART, RLENGTH)
      current=substr(current, 1, RSTART-1)
      sub(/^[[:space:]]*\(depends:[[:space:]]*/, "", annotation)
      sub(/\)[[:space:]]*$/, "", annotation)
      count=split(annotation, deps, ",")
      for (i=1; i<=count; i++) {
        dep=trim(deps[i])
        if (dep != "") pending[current]=pending[current] (pending[current] == "" ? "" : ",") dep
      }
    }
    current=trim(current)
    if (current == "") report("line " NR " has empty group name")
    else if (seen[current]++) report("line " NR " duplicate group name " current)
    groups[current]=1
    next
  }
  /^- \[[ x]\] / {
    task_count++
    if (!header_count && !task_before_header) task_before_header=NR
    files=value_for($0, "Files", "Validate")
    validate=value_for($0, "Validate", "Files")
    if (files == "") report("line " NR " task missing or empty Files:")
    if (validate == "") report("line " NR " task missing or empty Validate:")
  }
  END {
    if (!task_count) report("tasks file has no task lines")
    if (!header_count) report("tasks.md has no group header")
    if (task_before_header) report("line " task_before_header " task appears before first group header")
    for (group in groups) {
      count=split(pending[group], deps, ",")
      for (i=1; i<=count && pending[group] != ""; i++) {
        dep=deps[i]
        if (!(dep in groups)) report("group " group " has unknown dependency " dep)
        else if (dep == group) report("group " group " depends on itself")
        else dependencies[group SUBSEP dep]=1
      }
    }
    for (group in groups) if (!state[group]) visit(group)
    if (failed) exit 1
  }
' "$tasks" || exit 1

if [ "$mode" = "completion" ]; then
  require_approved "$spec" "spec.md"
  require_approved "$tasks" "tasks.md"
  require_closed_tasks "$tasks"
  echo "PASS: $track cycle intact"
else
  echo "PASS: $track structure valid"
fi
