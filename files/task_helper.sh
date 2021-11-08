#!/usr/bin/env bash

# Exit with an error message and error code, defaulting to 1
fail() {
  # Print a stderr: entry if there were anything printed to stderr
  if [[ -s $_tmp ]]; then
    # Hack to try and output valid json by replacing " with \" and removing unprintable characters.
    echo "{ \"status\": \"error\", \"message\": \"$1\", \"stderr\": \"$(sed 's/"/\\"/g' "$_tmp" | tr -cd '[:print:]')\" }"
  else
    echo "{ \"status\": \"error\", \"message\": \"$1\" }"
  fi

  exit ${2:-1}
}

success() {
  echo "$1"
  exit 0
}

# Test for colors. If unavailable, unset variables are ok
# shellcheck disable=SC2034
if tput colors &>/dev/null; then
  green="$(tput setaf 2)"
  red="$(tput setaf 1)"
  reset="$(tput sgr0)"
fi

# Redirect stderr to a temporary file so we can return it upon error.
# In *nix, any command run in this context or one `fork`ed from it,
#   e.g. subshells, command substitutions, process substitutions, etc,
#   will inherit this context, including the redirected file descriptor
# That is, everything run in this script will redirect stderr to this file
#   unless explicitly redirected as part of the command
_tmp="$(mktemp)"
exec 2>>"$_tmp"

# Use indirection to munge PT_ environment variables
# e.g. "$PT_version" becomes "$version"
for v in ${!PT_*}; do
  declare "${v#*PT_}"="${!v}"
done
