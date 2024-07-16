#!/usr/bin/env bash

# shellcheck disable=SC1090,SC2154
# This is disabled in CI, but we'll disable it here as well
declare PT__installdir
source "$PT__installdir/bash_task_helper/files/task_helper.sh"

if [ "$run_type" == 'fail' ]; then
  task-fail "This task failed"
elif [ "$run_type" == 'pass' ]; then
  task-succeed "This task succeeded"
elif [ "$run_type" == 'output' ]; then
  task-output "string1" "abcd"
  task-output "string-numeric" 42
  task-output-json "string2" '"abcd"'
  task-output-json "number" 42
  task-output-json "bool" true
  task-output "complex-string" $'This is a "complex string".\n\tSecond line.'
  task-output "escape-backslash" "\\ No newline"
fi

task-succeed
