# bash_task_helper

A Bash helper library for use by Puppet Tasks.

## Table of Contents

1. [Description](#description)
1. [Requirements](#requirements)
1. [Setup - The basics of getting started with bash_task_helper](#setup)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Available functions](#available-functions)
1. [Development - Guide for contributing to the module](#How-to-Report-an-issue-or-contribute-to-the-module)

## Description

This library handles producing a formatted error message for errors from stderr and uses indirection to munge PT_ environment variables.

### Requirements 

* bash >= 4.0 on the primary Puppet server

## Setup

To use this, include this module in a Puppetfile:

```ruby
mod 'puppetlabs-bash_task_helper'
```

Add it to your task metadata:

```
{
  "files": ["bash_task_helper/files/task_helper.sh"],
  "input_method": "environment"
}
```

## Usage

In your task, source the helper script and you can use the fail and sucess functions. Sucess outputs your provided output and fail outputs any provided output and appends stderr if applicable.

`mymodule/tasks/mytask.sh`

```
#!/bin/bash

declare PT__installdir
source "$PT__installdir/bash_task_helper/files/task_helper.sh"

if puppet resource service puppet | grep -q stopped; then
    #Start the Puppet service
     puppet resource service puppet ensure=running || task-fail "Couldn't start puppet service"
else
  task-fail "Puppet is already running or not installed"
fi

task-succeed
```

## Available functions

### `task-fail`

This function ends the task. The task will return as failed. The function
accepts an argument to set the task's return message, and an optional
exit code to use.

- `$1`: A text string message to return in the task's `message` key.
- `$2`: A non-zero integer to use as the task's exit code.

**Examples**

End the task with a failing status.

```bash
task-fail
```

End the task with a failing status and message.

```bash
task-fail "task failed because of reasons"
```

End the task with a failing status, message, and exit code.

```bash
task-fail "task failed because of reasons" "127"
```

### `task-succeed`

This function ends the task. The task will return as successful. The
function accepts an argument to set the task's return message.

- `$1`: A text string message to return in the task's `message` key.

**Examples**

End the task with a successful status.

```bash
task-succeed
```

End the task with a successful status and message.

```bash
task-succeed "task completed successfully
```

### `task-output`

This function adds keys and values to the task output. It takes a key
argument and a value argument and adds them to the task output when the
task exits.

- `$1`: The output key. Should only include letters, digits, hyphens (`-`),
  and underscores (`_`).
- `$2`: The output value. Should be a string. Values are automatically
  JSON-escaped.

**Examples**

Add values to the task output.

```bash
task-output "message" "an armadillo crossed the street"
task-output "maximum" "100GB"
```

### `task-output-json`

This function adds keys and values to the task output. It takes a key
argument and a value argument and adds them to the task output when the
task exits. This function requires the task author pass valid JSON as
the value, otherwise malformed task output will be produced.

- `$1`: The output key. Should only include letters, digits, hyphens (`-`),
  and underscores (`_`).
- `$2`: The output value. Should be pre-formatted, valid JSON.

**Examples**

Add values to the task output.

```bash
task-output "number" 42
task-output "string" '"str"'
task-output "object" '{"one": "two"}'
task-output "array" '["zero", "one", "two"]'
```

### `task-verbose-output`

Normally, tasks do not return all output if the task returns successfully.
This function ensures the task returns all output, regardless of exit code.

- `$1`: `true` or `false`. Defaults to `true`. Pass `false` to turn verbose
  output off.

**Examples**

Enable verbose output.

```bash
task-verbose-output
```

Disable verbose output.

```bash
task-verbose-output false
```

### `task-json-escape`

This function attempts to JSON-escape text input. Because the function is
constrained to rely only on lowest-common-denominator posix utilities, it may
not be able to fully escape all text on all platforms.

- `$1`: The value to JSON-escape.

**Examples**

JSON-escape a printed string.

```bash
printf "a string\nwith newlines\n" | task-json-escape
```

JSON-escape the contents of a file.

```bash
task-json-escape < file.txt
```

### `task-exit`

This function is called by a task helper EXIT trap. It will print JSON task
return data on task termination. The return data will include all output keys
set using `task-output`, and all uncaptured stdout/stderr output produced by the
script. This function should not be directly invoked, except inside a
user-created EXIT trap.

- `$1`: Exit code to terminate the task with. Defaults to `$?`.

**Examples**

Exit the task.

```bash
task-exit
```

Exit the task with an exit code.

```bash
task-exit 1
```

## How to Report an issue or contribute to the module

If you are a PE user and need support using this module or are encountering issues, our Support team would be happy to help you resolve your issue and help reproduce any bugs. Just raise a ticket on the [support portal](https://support.puppet.com/hc/en-us/requests/new).

If you have a reproducible bug or are a community user you can raise it directly on the Github issues page of the module [here.](https://github.com/elainemccloskey/bash_task_helper/issues) We also welcome PR contributions to improve the module. Please see further details about contributing [here](https://puppet.com/docs/puppet/7.5/contributing.html#contributing_changes_to_module_repositories).
