#!/usr/bin/env bash
# install.sh links the on-track skills into a harness skills directory
# and the command wrappers into a harness commands directory.
# Usage: install.sh [--agents-dir DIR] [--claude-dir DIR] [--commands-dir DIR]
# Defaults: ~/.agents/skills, ~/.claude/skills, ~/.claude/commands.
# When --claude-dir is set and --commands-dir is omitted, commands default to
# a sibling commands directory of that skills dir.
set -euo pipefail

method_root="$(cd "$(dirname "$0")" && pwd)"
agents_dir="$HOME/.agents/skills"
claude_dir="$HOME/.claude/skills"
commands_dir=""
claude_dir_set=0

while [ $# -gt 0 ]; do
  case "$1" in
    --agents-dir) agents_dir="${2:-}"; shift 2;;
    --claude-dir) claude_dir="${2:-}"; claude_dir_set=1; shift 2;;
    --commands-dir) commands_dir="${2:-}"; shift 2;;
    *) echo "ERROR: unknown argument: $1" >&2; exit 1;;
  esac
done

if [ -z "$commands_dir" ]; then
  if [ "$claude_dir_set" -eq 1 ]; then
    commands_dir="$(dirname "$claude_dir")/commands"
  else
    commands_dir="$HOME/.claude/commands"
  fi
fi

relpath() {
  local from_dir to result
  from_dir="$(cd "${1%/}" && pwd)"
  if [ -d "${2%/}" ]; then
    to="$(cd "${2%/}" && pwd)"
  else
    to="$(cd "$(dirname "${2%/}")" && pwd)/$(basename "${2%/}")"
  fi
  result=""
  while [ "$from_dir" != "/" ] && [ "${to#"$from_dir"/}" = "$to" ]; do
    from_dir="$(dirname "$from_dir")"
    result="${result}../"
  done
  if [ "$from_dir" = "/" ]; then
    printf '%s%s' "$result" "${to#/}"
  else
    printf '%s%s' "$result" "${to#"$from_dir"/}"
  fi
}

mkdir -p "$agents_dir"
for skill in "$method_root"/skills/ot-*; do
  [ -d "$skill" ] || continue
  ln -sfn "$skill" "$agents_dir/$(basename "$skill")"
  echo "linked $(basename "$skill") -> $agents_dir"
done

if [ -d "$(dirname "$claude_dir")" ]; then
  mkdir -p "$claude_dir"
  for skill in "$method_root"/skills/ot-*; do
    link="$agents_dir/$(basename "$skill")"
    [ -e "$link" ] || continue
    ln -sfn "$(relpath "$claude_dir" "$link")" "$claude_dir/$(basename "$link")"
  done
  echo "claude mirrors updated in $claude_dir"
fi

mkdir -p "$commands_dir"
for cmd in "$method_root"/commands/ot-*.md; do
  [ -f "$cmd" ] || continue
  ln -sfn "$cmd" "$commands_dir/$(basename "$cmd")"
  echo "linked $(basename "$cmd") -> $commands_dir"
done
