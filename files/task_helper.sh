#!/bin/bash

# Public: Set status=error, set a message, and exit the task
#
# This function ends the task. The task will return as failed. The function
# accepts an argument to set the task's return message, and an optional exit
# code to use.
#
# $1 - Message. A text string message to return in the task's `message` key.
# $2 - Exit code. A non-zero integer to use as the task's exit code.
#
# Examples
#
#   task-fail
#   task-fail "task failed because of reasons"
#   task-fail "task failed because of reasons" "127"
#
task-fail() {
  task-output "status" "error"
  task-output "message" "${1:(no message given)}"
  exit ${2:-1}
}

# Public: Set status=success, set a message, and exit the task
#
# This function ends the task. The task will return as successful. The function
# accepts an argument to set the task's return message.
#
# $1 - Message. A text string message to return in the task's `message` key.
#
# Examples
#
#   task-succeed
#   task-succeed "task completed successfully"
#
task-succeed() {
  task-output "status" "success"
  task-output "message" "${1:(no message given)}"
  exit 0
}

# Public: Set a task output key to a string value
#
# Takes a key argument and a value argument, and ensures that upon task exit
# the key and value will be returned as part of the task output.
#
# $1 - Output key. Should contain only characters that match [A-Za-z0-9-_]
# $2 - Output value. Should be a string. Will be json-escaped.
#
# Examples
#
#   task-output "message" "an armadilo crossed the street"
#   task-output "maximum" "100"
#
task-output() {
  local key="${1}"
  local value=$(echo -n "$2" | task-json-escape)

  # Try to find an index for the key
  for i in "${!_task_output_keys[@]}"; do
    [[ "${_task_output_keys[$i]}" = "${key}" ]] && break
  done

  # If there's an index, set its value. Otherwise, add a new key
  if [[ "${_task_output_keys[$i]}" = "${key}" ]]; then
    _task_output_values[$i]="${value}"
  else
    _task_output_keys=("${_task_output_keys[@]}" "${key}")
    _task_output_values=("${_task_output_values[@]}" "${value}")
  fi
}

# Public: read text on stdin and output the text json-escaped
#
# A filter command which does its best to json-escape text input. Because the
# function is constrained to rely only on lowest-common-denominator posix
# utilities, it may not be able to fully escape all text on all platforms.
#
# Examples
#
#   printf "a string\nwith newlines\n" | task-json-escape
#   task-json-escape < file.txt
#
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

# Private: Print json task return data on task exit
#
# This function is called by a task helper EXIT trap. It will print json task
# return data on task termination.  The return data will include all output
# keys set using task-output, and all uncaptured stdout/stderr output produced
# by the script. This function should not be directly invoked.
#
# Examples
#
#   _task-exit
#
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
  for i in "${!_task_output_keys[@]}"; do
    printf '  "%s": "%s",\n' "${_task_output_keys[$i]}" "${_task_output_values[$i]}"
  done
  printf '  "_output": "%s"\n' "$(task-json-escape < "$_output_tmpfile")"
  printf '}\n'

  # Remove the output tempfile
  rm "$_output_tmpfile"

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

# Set up variables to record task outputs
_task_output_keys=()
_task_output_values=()

# Redirect all output (stdin, stderr) to a tempfile, and trap EXIT. Upon exit,
# print a Bolt task return JSON string, with the full contents of the tempfile
# in the "_output" key.
_output_tmpfile="$(mktemp)"
trap _task-exit EXIT
exec 3>&1 \
     4>&2 \
     1>> "$_output_tmpfile" \
     2>&1
