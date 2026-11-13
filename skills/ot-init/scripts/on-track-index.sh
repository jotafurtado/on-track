#!/usr/bin/env bash
# on-track-index.sh generates on-track/INDEX.md from frontmatter and validates.
# Usage: on-track-index.sh [repo-root]. Fails with an objective message on invalid input.
# Frontmatter uses a canonical subset, not general YAML: line 1 is exactly `---`, the next line
# that is exactly `---` closes the block, each non-blank line between them is one `key: value`
# field (key matches [a-z][a-z0-9_]*, value may be empty, a flow list [a, b] is one value), and
# no key appears twice. Fields are read only from the block that opens on line 1.
set -euo pipefail

export LC_ALL=C

root="${1:-.}"
ai="$root/on-track"
errors=0
track_rows=""
ref_rows=""
research_rows=""
assessment_rows=""
decision_rows=""
handoff_rows=""

fail() { echo "ERROR: $1" >&2; errors=$((errors + 1)); }

field() {
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

frontmatter_ok() {
  local violation
  violation="$(frontmatter_violation "$1")"
  [ -z "$violation" ] && return 0
  fail "$2 $violation"
  return 1
}

phase_approved() {
  local file="$1"
  local violation status
  [ -f "$file" ] && [ -r "$file" ] || return 1
  violation="$(frontmatter_violation "$file" 2>/dev/null)" || return 1
  [ -z "$violation" ] || return 1
  status="$(field "$file" status 2>/dev/null)" || return 1
  [ "$status" = "approved" ]
}

track_phase() {
  local directory="$1"
  local status="$2"
  local spec="$directory/spec.md"
  local tasks="$directory/tasks.md"
  local progress
  if [ "$status" != "draft" ]; then
    printf '%s' '-'
  elif [ ! -f "$spec" ] && [ ! -f "$tasks" ]; then
    printf '%s' 'intent'
  elif phase_approved "$spec" && phase_approved "$tasks"; then
    if progress="$(awk '/^- \[[ x]\] / { total++ } /^- \[x\] / { checked++ }
      END { printf "implement %d/%d", checked, total }' "$tasks" 2>/dev/null)"; then
      printf '%s' "$progress"
    else
      printf '%s' 'spec'
    fi
  else
    printf '%s' 'spec'
  fi
}

validate_flow_list() {
  local file="$1"
  local key="$2"
  local category="$3"
  local value="${4:-}"
  local list slug target
  local -a slugs
  [ -z "$value" ] && return
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  if [[ ! "$value" =~ ^\[[^][]*\]$ ]]; then
    fail "$(basename "$file") $key must use [a, b] list form"
    return
  fi
  list="${value:1:${#value}-2}"
  [ -z "${list//[[:space:]]/}" ] && return
  IFS=',' read -r -a slugs <<< "$list"
  for slug in "${slugs[@]}"; do
    slug="${slug#"${slug%%[![:space:]]*}"}"
    slug="${slug%"${slug##*[![:space:]]}"}"
    if [ -z "$slug" ]; then
      fail "$(basename "$file") $key contains an empty slug"
      continue
    fi
    target="$ai/$category/$slug.md"
    [ -f "$target" ] || fail "$(basename "$file") $key references missing $slug"
  done
}

validate_superseded() {
  local file="$1"
  local category="$2"
  local id="$3"
  local required="$4"
  local replacement
  local target
  replacement="$(field "$file" superseded_by || true)"
  if [ -z "$replacement" ]; then
    if [ "$required" = "yes" ]; then fail "$(basename "$file") superseded without superseded_by"; fi
    return 0
  fi
  if [ "$replacement" = "$id" ]; then
    fail "$(basename "$file") superseded_by has a self-reference: $replacement"
    return
  fi
  if [ "$category" = "tracks" ]; then
    target="$ai/tracks/$replacement/intent.md"
  else
    target="$ai/$category/$replacement.md"
  fi
  [ -f "$target" ] || fail "$(basename "$file") superseded_by references missing $replacement"
}

require_heading() {
  local file="$1"
  local heading="$2"
  grep -Fqx "$heading" "$file" || fail "$(basename "$file") missing heading: $heading"
}

require_heading_prefix() {
  local file="$1"
  local prefix="$2"
  grep -Fq "$prefix" "$file" || fail "$(basename "$file") missing heading prefix: $prefix"
}

sha256_text() {
  printf '%s' "$1" | shasum -a 256 | awk '{print $1}'
}

inline_source_hash() {
  awk '
    /^## Source content$/ { found=1; next }
    found && !separator_checked {
      separator_checked=1
      if ($0 == "") next
    }
    found { sub(/\r$/, ""); print }
  ' "$1" | shasum -a 256 | awk '{print $1}'
}

if [ ! -d "$ai/tracks" ]; then
  echo "ERROR: $ai/tracks missing. Run on-track-init.sh first." >&2
  exit 1
fi

tmp_index="$(mktemp "$ai/.INDEX.md.XXXXXX")"
trap 'rm -f "$tmp_index"' EXIT

for track_dir in "$ai"/tracks/*/; do
  [ -d "$track_dir" ] || continue
  [ -f "$track_dir/intent.md" ] || fail "$(basename "$track_dir") missing intent.md"
done

for intent in "$ai"/tracks/*/intent.md; do
  [ -f "$intent" ] || continue
  track="$(basename "$(dirname "$intent")")"
  frontmatter_ok "$intent" "$track/intent.md" || continue
  id="$(field "$intent" id || true)"
  status="$(field "$intent" status || true)"
  [[ "$track" =~ ^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "$track invalid track directory name"
  [ -n "$id" ] || { fail "$track missing id field"; continue; }
  [ -n "$status" ] || { fail "$track missing status field"; continue; }
  [ "$id" = "$track" ] || fail "$track id mismatch: $id"
  case "$status" in draft|shipped|dropped|superseded) ;; *) fail "$track invalid status: $status";; esac
  for category in refs research assessments decisions; do
    validate_flow_list "$intent" "$category" "$category" "$(field "$intent" "$category" || true)"
  done
  validate_superseded "$intent" tracks "$id" "$([ "$status" = "superseded" ] && echo yes || echo no)"
  phase="$(track_phase "$(dirname "$intent")" "$status")"
  track_rows="$track_rows| $track | $status | $phase |"$'\n'
done

if [ -d "$ai/refs" ]; then
  for ref in "$ai"/refs/*; do
    [ -f "$ref" ] || continue
    name="$(basename "$ref")"
    stem="${name%.md}"
    frontmatter_ok "$ref" "$name" || continue
    size="$(wc -c < "$ref" | tr -d ' ')"
    ref_type="$(field "$ref" type || true)"
    captured="$(field "$ref" captured || true)"
    owner="$(field "$ref" owner || true)"
    sha256="$(field "$ref" sha256 || true)"
    content_license="$(field "$ref" content_license || true)"
    source="$(field "$ref" source || true)"
    pin="$(field "$ref" pin || true)"
    retrieved_at="$(field "$ref" retrieved_at || true)"
    status="$(field "$ref" status || true)"

    [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*\.md$ ]] || fail "$name invalid ref filename; expected slug.md"
    [ "$size" -le 512000 ] || fail "$name over 500 KB ($size bytes)"
    [ -n "$captured" ] || fail "$name missing captured field"
    [ -n "$owner" ] || fail "$name missing owner field"
    [ -n "$content_license" ] || fail "$name missing content_license field"
    [[ "$sha256" =~ ^[0-9a-f]{64}$ ]] || fail "$name invalid sha256; expected 64 lowercase hex characters"
    [ -z "$status" ] || fail "$name must not have a status field"

    case "$ref_type" in
      inline)
        [ -z "$source" ] || fail "$name inline ref must not have source"
        [ -z "$pin" ] || fail "$name inline ref must not have pin"
        [ -z "$retrieved_at" ] || fail "$name inline ref must not have retrieved_at"
        require_heading "$ref" "## Source content"
        calculated_inline_hash="$(inline_source_hash "$ref")"
        [ "$sha256" = "$calculated_inline_hash" ] || fail "$name sha256 does not match normalized inline source content"
        ;;
      pointer)
        [ -n "$source" ] || fail "$name pointer ref missing source field"
        if [ -n "$pin" ] && [ -n "$retrieved_at" ]; then
          fail "$name pointer ref must use pin or retrieved_at, not both"
        elif [ -z "$pin" ] && [ -z "$retrieved_at" ]; then
          fail "$name pointer ref requires pin or retrieved_at"
        fi
        if [ -n "$source" ] && [ "$sha256" = "$(sha256_text "$source")" ]; then
          fail "$name sha256 hashes the source locator instead of observed content"
        fi
        ;;
      *) fail "$name invalid type: ${ref_type:-missing}";;
    esac

    for earlier_ref in "$ai"/refs/*; do
      [ -f "$earlier_ref" ] || continue
      [ "$earlier_ref" = "$ref" ] && break
      earlier_hash="$(field "$earlier_ref" sha256 || true)"
      if [ -n "$sha256" ] && [ "$sha256" = "$earlier_hash" ]; then
        fail "$name duplicates content hash from $(basename "$earlier_ref")"
        break
      fi
    done

    ref_rows="$ref_rows| $stem | ${ref_type:-missing} | $captured |"$'\n'
  done
fi

if [ -d "$ai/research" ]; then
  for research in "$ai"/research/*; do
    [ -f "$research" ] || continue
    name="$(basename "$research")"
    stem="${name%.md}"
    frontmatter_ok "$research" "$name" || continue
    captured="$(field "$research" captured || true)"
    owner="$(field "$research" owner || true)"
    status="$(field "$research" status || true)"
    singular_source="$(field "$research" source || true)"

    [[ "$name" =~ ^[a-z0-9]+(-[a-z0-9]+)*\.md$ ]] || fail "$name invalid research filename; expected slug.md"
    [ -n "$captured" ] || fail "$name missing captured field"
    [ -n "$owner" ] || fail "$name missing owner field"
    [ -z "$status" ] || fail "$name must not have a status field"
    [ -z "$singular_source" ] || fail "$name must not have a singular source field"
    require_heading "$research" "## Question"
    require_heading "$research" "## Conclusion"
    require_heading "$research" "## Conflicts"
    require_heading "$research" "## Limitations"
    require_heading_prefix "$research" "## Sources"
    research_rows="$research_rows| $stem | $captured |"$'\n'
  done
fi

if [ -d "$ai/assessments" ]; then
  for assessment in "$ai"/assessments/*; do
    [ -f "$assessment" ] || continue
    name="$(basename "$assessment")"
    stem="${name%.md}"
    frontmatter_ok "$assessment" "$name" || continue
    captured="$(field "$assessment" captured || true)"
    owner="$(field "$assessment" owner || true)"
    scope="$(field "$assessment" scope || true)"
    evaluator="$(field "$assessment" evaluator || true)"
    tracks="$(field "$assessment" tracks || true)"
    status="$(field "$assessment" status || true)"

    [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]] || fail "$name invalid assessment filename; expected YYYY-MM-DD-slug.md"
    [ -n "$captured" ] || fail "$name missing captured field"
    [ -n "$owner" ] || fail "$name missing owner field"
    [ -n "$scope" ] || fail "$name missing scope field"
    [ -n "$evaluator" ] || fail "$name missing evaluator field"
    [ -n "$tracks" ] || fail "$name missing tracks field"
    [ -z "$status" ] || fail "$name must not have a status field"
    file_date="${stem:0:10}"
    [ -z "$captured" ] || [ "$captured" = "$file_date" ] || fail "$name captured $captured does not match filename date $file_date"
    require_heading "$assessment" "## Conclusion"
    require_heading "$assessment" "## Scope and basis"
    require_heading "$assessment" "## Criteria"
    require_heading "$assessment" "## Findings"
    require_heading "$assessment" "## Evidence against conclusion"
    require_heading "$assessment" "## Limitations"
    require_heading "$assessment" "## Recommendations"
    assessment_rows="$assessment_rows| $stem | $captured |"$'\n'
  done
fi

if [ -d "$ai/decisions" ]; then
  for decision in "$ai"/decisions/*; do
    [ -f "$decision" ] || continue
    name="$(basename "$decision")"
    stem="${name%.md}"
    frontmatter_ok "$decision" "$name" || continue
    id="$(field "$decision" id || true)"
    status="$(field "$decision" status || true)"
    date="$(field "$decision" date || true)"
    owner="$(field "$decision" owner || true)"

    [[ "$name" =~ ^[0-9]{3}-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]] || fail "$name invalid decision filename; expected NNN-slug.md"
    [ -n "$id" ] || fail "$name missing id field"
    [ -n "$status" ] || fail "$name missing status field"
    [ -n "$date" ] || fail "$name missing date field"
    [ -n "$owner" ] || fail "$name missing owner field"
    [ -z "$id" ] || [ "$id" = "$stem" ] || fail "$name id mismatch: $id"
    case "$status" in
      accepted|superseded) ;;
      *) fail "$name invalid status: ${status:-missing}";;
    esac
    validate_superseded "$decision" decisions "$stem" "$([ "$status" = "superseded" ] && echo yes || echo no)"
    require_heading "$decision" "## Context"
    require_heading "$decision" "## Decision"
    require_heading "$decision" "## Rationale"
    require_heading "$decision" "## Alternatives considered"
    require_heading "$decision" "## Consequences"
    decision_rows="$decision_rows| $stem | $status |"$'\n'
  done
fi

captured_epoch() {
  awk -v value="$1" 'BEGIN {
    year=substr(value,1,4)+0
    month=substr(value,6,2)+0
    day=substr(value,9,2)+0
    hour=substr(value,12,2)+0
    minute=substr(value,15,2)+0
    second=substr(value,18,2)+0
    month_adjusted=month+(month>2 ? -3 : 9)
    year_adjusted=year-(month<=2)
    era=int(year_adjusted/400)
    year_of_era=year_adjusted-era*400
    day_of_year=int((153*month_adjusted+2)/5)+day-1
    day_of_era=year_of_era*365+int(year_of_era/4)-int(year_of_era/100)+day_of_year
    days=era*146097+day_of_era-719468
    print days*86400+hour*3600+minute*60+second
  }'
}

handoff_sort_rows=()
active_handoffs=0
if [ -d "$ai/handoffs" ]; then
  for handoff in "$ai"/handoffs/*; do
    [ -f "$handoff" ] || continue
    active_handoffs=$((active_handoffs + 1))
    name="$(basename "$handoff")"
    stem="${name%.md}"
    frontmatter_ok "$handoff" "$name" || continue
    captured="$(field "$handoff" captured || true)"
    owner="$(field "$handoff" owner || true)"
    focus="$(field "$handoff" focus || true)"
    status="$(field "$handoff" status || true)"
    name_ok=0
    if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}Z-[a-z0-9]+(-[a-z0-9]+)*\.md$ ]]; then
      name_ok=1
    else
      fail "$name invalid handoff filename; expected YYYY-MM-DD-HHmmssZ-slug.md"
    fi
    if [[ ! "$captured" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]; then
      fail "$name invalid captured timestamp; expected YYYY-MM-DDTHH:MM:SSZ"
      epoch=0
    else
      epoch="$(captured_epoch "$captured")"
    fi
    if [ "$name_ok" = "1" ]; then
      filename_instant="${stem:0:10}T${stem:11:2}:${stem:13:2}:${stem:15:2}Z"
      [ "$captured" = "$filename_instant" ] || fail "$name filename timestamp does not match captured $captured"
    fi
    [ -n "$owner" ] || fail "$name missing owner field"
    [ -n "$focus" ] || fail "$name missing focus field"
    [ -z "$status" ] || fail "$name must not have a status field"
    require_heading "$handoff" "## Objective"
    require_heading "$handoff" "## Active user instructions, verbatim"
    require_heading "$handoff" "## Current state"
    require_heading "$handoff" "## Completed"
    require_heading "$handoff" "## Unresolved decisions"
    require_heading "$handoff" "## Relevant paths and durable artifacts"
    require_heading "$handoff" "## Observed command results"
    require_heading "$handoff" "## Blockers and risks"
    grep -Fqx "## Next actions" "$handoff" || fail "$name missing heading ## Next actions"
    handoff_sort_rows+=("$epoch"$'\t'"$name"$'\t'"$captured")
  done
fi
[ "$active_handoffs" -le 3 ] || fail "more than three handoffs are active"
if [ "${#handoff_sort_rows[@]}" -gt 0 ]; then
  while IFS=$'\t' read -r epoch name captured; do
    handoff_rows="$handoff_rows| ${name%.md} | $captured |"$'\n'
  done < <(printf '%s\n' "${handoff_sort_rows[@]}" | sort -t $'\t' -k1,1n -k2,2)
fi

{
  printf '# INDEX\n\nGenerated by on-track-index. Do not edit by hand.\n\n'
  printf '| track | status | phase |\n|---|---|---|\n%s' "$track_rows"
  printf '\n| ref | type | captured |\n|---|---|---|\n%s' "$ref_rows"
  printf '\n| research | captured |\n|---|---|\n%s' "$research_rows"
  printf '\n| assessment | captured |\n|---|---|\n%s' "$assessment_rows"
  printf '\n| decision | status |\n|---|---|\n%s' "$decision_rows"
  printf '\n| handoff | captured |\n|---|---|\n%s' "$handoff_rows"
} > "$tmp_index"

if [ "$errors" -gt 0 ]; then
  echo "INDEX not updated: $errors error(s)." >&2
  exit 1
fi

mv "$tmp_index" "$ai/INDEX.md"
echo "INDEX ok at $ai/INDEX.md"
