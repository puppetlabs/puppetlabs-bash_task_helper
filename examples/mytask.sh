#!/bin/bash

declare PT__installdir
source "$PT__installdir/bash_task_helper/files/task_helper.sh"


if puppet resource service puppet | grep -q stopped; then
    #Start the Puppet service
     puppet resource service puppet ensure=running || fail "Couldn't start puppet service"

else
  fail "Puppet is already running or not installed"
fi


success '{ "status": "success" }'