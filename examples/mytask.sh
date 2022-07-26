#!/usr/bin/env bash

# shellcheck disable=SC1090
# This is disabled in CI, but we'll disable it here as well
declare PT__installdir
source "$PT__installdir/bash_task_helper/files/task_helper.sh"

if puppet resource service puppet | grep -q stopped; then
    #Start the Puppet service
     puppet resource service puppet ensure=running || task-fail "Couldn't start puppet service"
else
  task-fail "Puppet is already running or not installed"
fi

task-succeed
