#!/usr/bin/env bash

# Exit with an error message and error code, defaulting to 1
task-fail() {
  task-output "status" "error"
  task-output "message" "$1"
  exit ${2:-1}
}

task-succeed() {
  task-output "status" "success"
  if [ "$#" -gt 0 ]; then
    task-output "message" "$*"
  fi
  exit 0
}

# No arguments. Use with a pipe or input redirect as a filter.
task-json-escape() {
  # This is imperfect, and will miss some characters. If we can figure out a
  # way to get iconv to catch more character types, we might improve that.
  # 1. Replace backslashes with escape sequences
  # 2. Replace unicode characters (if possible) with system iconv
  # 3. Replace other required characters with escape sequences
  #    Note that this includes two control-characters specifically
  # 4. Escape newlines (1/2): Replace all newlines with literal tabs
  # 5. Escape newlines (2/2): Replace all literal tabs with newline escape sequences
  # 6. Delete any remaining non-printable lines from the stream
  sed -e 's/\\/\\/g' \
    | { iconv -t ASCII --unicode-subst="\u%04x" || cat; } \
    | sed -e 's/"/\\"/' \
          -e 's/\//\\\//g' \
          -e "s/$(printf '\b')/\\\b/" \
          -e "s/$(printf '\f')/\\\f/" \
          -e 's/\r/\\r/g' \
          -e 's/\t/\\t/g' \
          -e "s/$(printf "\x1b")/\\\u001b/g" \
          -e "s/$(printf "\x0f")/\\\u000f/g" \
    | tr '\n' '\t' \
    | sed 's/\t/\\n/g' \
    | tr -cd '\11\12\15\40-\176'
}

task-output() {
  local key="${1}"
  local value=$(task-json-escape <<< "$2")
  # TODO: ensure no duplicate values
  _task_outputs="${_task_outputs}\"${key}\": \"${value%\\n}\",\n  "
}

_task-exit() {
  # Record the exit code
  local exit_code=$?

  # Unset the trap
  trap - EXIT

  # Reset outputs
  exec 1>&3
  exec 2>&4

  # Print JSON to stdout
  printf '{\n'
  printf '  %s' "$(printf "$_task_outputs")"
  printf '%s\n' "\"merged_output\": \"$(task-json-escape < "$_merged_output")\""
  printf '}\n'

  # Remove the output tempfile
  rm "$_merged_output"

  # Resume an orderly exit
  exit "$exit_code"
}

# Test for colors. If unavailable, unset variables are ok
# shellcheck disable=SC2034
if tput colors &>/dev/null; then
  green="$(tput setaf 2)"
  red="$(tput setaf 1)"
  reset="$(tput sgr0)"
fi

# Use indirection to munge PT_ environment variables
# e.g. "$PT_version" becomes "$version"
for v in ${!PT_*}; do
  declare "${v#*PT_}"="${!v}"
done

# Redirect all output to a tempfile, and trap EXIT. Upon exit, print a Bolt
# task return JSON string, with the full contents of the tempfile in the
# "merged_output" key.
_merged_output="$(mktemp)"
trap _task-exit EXIT
exec 3>&1
exec 4>&2
exec 1>> "$_merged_output"
exec 2>> "$_merged_output"
