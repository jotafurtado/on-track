#!/usr/bin/env bash
# on-track-doctor.sh diagnoses an on-track target repository and changes nothing.
# Usage: on-track-doctor.sh [repo-root].
# Prints one `FIND: <code>: <detail>` line per finding, then a summary line.
# Exit 0 when nothing is found, 1 when there is at least one finding, 2 on bad usage.
# Codes, in the order fixes must run:
#   legacy-tree        a fast-track-ai file, folder, or link in the root
#   legacy-block       a fast-track-ai managed block in AGENTS.md
#   block-missing      AGENTS.md has no on-track managed block
#   block-outdated     the on-track managed block differs from the installed snippet
#   tree-missing       a directory or file that ot-init creates is missing
#   adr-superseded     a superseded ADR still in on-track/decisions/
#   adr-untitled       an ADR heading repeats its id instead of a title
#   index-invalid      the index generator reports validation errors
set -euo pipefail

export LC_ALL=C

if [ "$#" -gt 1 ]; then
  echo "usage: on-track-doctor.sh [repo-root]" >&2
  exit 2
fi

root="${1:-.}"
if [ ! -d "$root" ]; then
  echo "ERROR: $root is not a directory" >&2
  exit 2
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
snippet="$script_dir/../../ot-init/assets/AGENTS-snippet.md"
index_script="$script_dir/../../ot-init/scripts/on-track-index.sh"
agents="$root/AGENTS.md"
ai="$root/on-track"
findings=0

find_line() { echo "FIND: $1: $2"; findings=$((findings + 1)); }

block_version() {
  sed -n '1s/^<!-- BEGIN MANAGED BLOCK: on-track \(v[0-9][0-9.]*\)\..*/\1/p'
}

field() {
  awk -v key="$2" 'NR == 1 { if ($0 != "---") exit; next } $0 == "---" { exit } index($0, key ":") == 1 {sub(/^[^:]+:[[:space:]]*/, ""); print; exit}' "$1"
}

legacy=no
if [ -e "$root/fast-track-ai" ] || [ -L "$root/fast-track-ai" ]; then
  find_line legacy-tree "rename fast-track-ai/ to on-track/ and replace fast-track-ai/ with on-track/ in the paths inside its files"
  legacy=yes
fi
if [ -f "$agents" ] && grep -q '^<!-- BEGIN MANAGED BLOCK: fast-track-ai' "$agents"; then
  find_line legacy-block "delete the fast-track-ai managed block in AGENTS.md, from its BEGIN marker to its END marker"
  legacy=yes
fi

if [ ! -f "$agents" ] || ! grep -q '^<!-- BEGIN MANAGED BLOCK: on-track' "$agents"; then
  find_line block-missing "AGENTS.md has no on-track managed block; ot-init writes it"
else
  block="$(awk '/^<!-- BEGIN MANAGED BLOCK: on-track/ { on=1 } on { print } on && /^<!-- END MANAGED BLOCK: on-track -->/ { exit }' "$agents")"
  if [ "$block" != "$(cat "$snippet")" ]; then
    project_version="$(printf '%s\n' "$block" | block_version)"
    package_version="$(block_version < "$snippet")"
    find_line block-outdated "project ${project_version:-no version}, package ${package_version:-unknown}; ot-init replaces the block in place"
  fi
fi

for directory in research refs handoffs/archive assessments decisions decisions/archive tracks crumbs; do
  [ -d "$ai/$directory" ] || find_line tree-missing "on-track/$directory/; ot-init creates it"
done
[ -f "$ai/crumbs/.gitignore" ] || find_line tree-missing "on-track/crumbs/.gitignore; ot-init creates it"
[ -f "$ai/INDEX.md" ] || find_line tree-missing "on-track/INDEX.md; ot-init seeds it"

if [ -d "$ai/decisions" ]; then
  for decision in "$ai"/decisions/*.md; do
    [ -f "$decision" ] || continue
    name="$(basename "$decision")"
    status="$(field "$decision" status || true)"
    if [ "$status" = "superseded" ]; then
      find_line adr-superseded "on-track/decisions/$name; move it to on-track/decisions/archive/$name"
    fi
    if [ "$status" != "superseded" ] && grep -Fqx "# ADR: ${name%.md}" "$decision"; then
      find_line adr-untitled "on-track/decisions/$name; replace the heading with # ADR: <short title>"
    fi
  done
fi

if [ "$legacy" = "no" ] && [ -d "$ai/tracks" ] && [ -x "$index_script" ]; then
  if ! index_output="$("$index_script" --check "$root" 2>&1 >/dev/null)"; then
    while IFS= read -r line; do
      case "$line" in
        *"is superseded; move it to decisions/archive/"*) ;;
        ERROR:*) find_line index-invalid "${line#ERROR: }";;
      esac
    done <<< "$index_output"
  fi
fi

if [ "$findings" -eq 0 ]; then
  echo "OK: nothing to fix in $root"
  exit 0
fi
echo "DOCTOR: $findings finding(s) in $root. Nothing was changed."
exit 1
