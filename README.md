# bash_task_helper

A Bash helper library for use by Puppet Tasks.

## Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup - The basics of getting started with bash_task_helper](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Development - Guide for contributing to the module](#How-to-Report-an-issue-or-contribute-to-the-module)

## Description

This library handles producing a formatted error message for errors from stderr and uses indirection to munge PT_ environment variables.

### Requirements 

* bash >= 4.0 on the primary Puppet server

## Setup

To use this, include this module in a Puppetfile

```mod 'puppetlabs-bash_task_helper'```

Add it to your task metadata 

```
{
  "files": ["bash_task_helper/files/task_helper.sh"],
  "input_method": "environment"
}
```

## Usage

In your task, source the helper script and you can use the fail and sucess funtions. Sucess outputs your provided output and fail outputs any provided output and appends stderr if applicable.

```mymodule/tasks/mytask.rb```

```
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

```

## How to Report an issue or contribute to the module

If you are a PE user and need support using this module or are encountering issues, our Support team would be happy to help you resolve your issue and help reproduce any bugs. Just raise a ticket on the [support portal](https://support.puppet.com/hc/en-us/requests/new).

If you have a reproducible bug or are a community user you can raise it directly on the Github issues page of the module [here.](https://github.com/puppetlabs/ca_extend/issues) We also welcome PR contributions to improve the module. Please see further details about contributing [here](https://puppet.com/docs/puppet/7.5/contributing.html#contributing_changes_to_module_repositories).