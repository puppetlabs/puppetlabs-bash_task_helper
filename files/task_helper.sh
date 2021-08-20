#!/bin/bash

# Exit with an error message and error code, defaulting to 1
fail() {
  # If we redirected stdout, send it back to its original destination
  [[ $PT_REDIRECTED ]] && exec >&3
  # Print a stderr: entry if there were anything printed to stderr
  if [[ -s $PT_TMP ]]; then
    # Hack to try and output valid json by replacing newlines with spaces.
    echo "{ \"status\": \"error\", \"message\": \"$1\", \"stderr\": \"$(tr '\n' ' ' <"$PT_TMP")\" }"
  else
    echo "{ \"status\": \"error\", \"message\": \"$1\" }"
  fi

  exit "${2:-1}"
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

PT_TMP="$(mktemp)"
# Default to redirecting stderr for backwards compatibility
case "${PT_LOGGING-stderr}" in
  'combined')
    exec 3>&1
    PT_REDIRECTED=true
    exec >>"$PT_TMP" 2>&1
    ;;
  'stderr')
    exec 2>>"$PT_TMP"
    ;;
  'clone_all')
    PT_REDIRECTED=true
    #TODO In bash 4.1+ we can ask the shell for the next available fd.  Can we figure it out in pure bash 3?
    # For now, document that we use 3 and 4 for preserving stderr and stdout
    exec 3>&1
    exec 4>&2

    # Redirect stdout and stderr to `tee` process substitutions.  The behavior of `tee` is to send the input it receives to stdout
    # This allows us to redirect that output, i.e. the stdout of each process substitution, to the original stdout and stderr
    exec > >(tee -a "$PT_TMP" >&3) 2> >(tee -a "$PT_TMP" >&4)
    ;;
  'clone_stderr')
    exec 3>&2
    exec 2> >(tee "$PT_TMP" >&3)
    ;;
  'none')
    true
    ;;
  *)
    fail "Invalid option for PT_LOGGING: $PT_LOGGING"
esac

# Use indirection to munge PT_ environment variables
# e.g. "$PT_version" becomes "$version"
for v in ${!PT_*}; do
  declare "${v#*PT_}"="${!v}"
done
