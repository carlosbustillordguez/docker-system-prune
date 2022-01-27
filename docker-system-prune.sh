#!/bin/bash
set -eo pipefail
#
# Prune the system by removing:
#
#  - all stopped containers
#  - all networks not used by at least one container
#  - all volumes not used by at least one container (by setting the `-v | --volumes` script argument)
#  - all images without at least one container associated to them
#  - all build cache
#
# The default value for USED_PERCENT_THRESHOLD is 75
#
# Usage:
#   ./docker-system-prune.sh -d DEVICE_NAME [ -t USED_PERCENT_THRESHOLD ] [ -v ]
#
# Example:
#   ./docker-system-prune.sh -d /dev/sda1
#
# To remove all volumes not used by at least one container:
#   ./docker-system-prune.sh -d /dev/sda1 -v
#
# By Carlos Miguel Bustillo Rdguez <https://linkedin.com/in/carlosbustillordguez/>
#
# Version: 1.1.0

# Global variables.
readonly SCRIPT_LOCK_FILE="/tmp/docker-system-prune-launched.lock"

# Main Function.
main() {
  check_requirements
  parse_cmdline "$@"
  check_arguments "$DEVICE_NAME" "$USED_PERCENT_THRESHOLD"
  docker_system_prune "$DEVICE_NAME" "$USED_PERCENT_THRESHOLD" "$PRUNE_VOLUMES"
} # => main()

#######################################################################
# Check if this script has a previous execution running.
# Globals:
#   SCRIPT_LOCK_FILE
# Arguments:
#   None
#######################################################################
check_if_already_lauched() {
  if [ -e "$SCRIPT_LOCK_FILE" ]; then
    echo "$(basename "$0"): There is a previous instance launched. Exiting..."
    exit 1
  else
    touch "$SCRIPT_LOCK_FILE"
  fi
} # => check_if_already_lauched()

#######################################################################
# Check the script requirements.
# Globals:
#   None
# Arguments:
#   None
#######################################################################
check_requirements() {
  if ! command -v docker > /dev/null; then
    echo "Docker is not installed in the system!"
    echo "Please follow the instructions:"
    echo "  * For Linux: https://docs.docker.com/engine/install/"
    echo "  * For MacOS: https://docs.docker.com/desktop/mac/install/"
    exit 1
  fi
} # => check_requirements()

#######################################################################
# Check script arguments
# Globals:
#   None
# Arguments:
#   device_name - a valid block device name, e.g: /dev/sda1
#   used_percent_threshold - the used percent threshold for device_name
#######################################################################
check_arguments() {
  local device_name="$1"
  local used_percent_threshold="${2:-"75"}"

  if [ -z "$device_name" ]; then
    echo "$(basename "$0"): Required argument not passed."
    echo "Usage:"
    echo "  $(basename "$0") -d DEVICE_NAME [ -t USED_PERCENT_THRESHOLD ]"
    echo "Example:"
    echo "  $(basename "$0") -d /dev/sda1"
    exit 1
  elif [ ! -b "$device_name" ]; then
    echo "The '$device_name' is not a valid block device on this system!"
    exit 1
  elif [[ $used_percent_threshold -lt 1 ]] || [[ $used_percent_threshold -gt 100 ]]; then
    echo "The used percent threshold must between 1 and 100!"
    exit 1
  fi
} # => check_arguments()

#######################################################################
# Docker prune system.
# Globals:
#   SCRIPT_LOCK_FILE
# Arguments:
#   device_name - a valid block device name, e.g: /dev/sda1
#   used_percent_threshold - the used percent threshold for device_name
#   prune_volumes - whether to prune or not all not used volumes
#######################################################################
docker_system_prune() {
  local device_name="$1"
  local used_percent_threshold="${2:-"75"}"
  local prune_volumes="$3"
  local exit_code=0

  # Get the current used space in percent
  used_percent=$(df -l | grep "$device_name" | awk '{print $5}' | sed 's/%//g') || true

  # Prune the system if the $USED_PERCENT is greater or equal than $used_percent_threshold
  if [[ $used_percent -ge $used_percent_threshold ]] && [[ "$used_percent" != "" ]]; then
    docker system prune --all --force --volumes="$prune_volumes"
    exit_code=$?
  elif [[ "$used_percent" == "" ]]; then
    echo "The '$device_name' block device is not mounted in the system!"
    exit_code=1
  fi

  # Remove the lock for this script
  [[ -e "$SCRIPT_LOCK_FILE" ]] && rm -f "$SCRIPT_LOCK_FILE"
  exit $exit_code
} # => docker_system_prune()

#######################################################################
# Parse script options.
# Globals:
#   DEVICE_NAME - the value of -d|--device argument
#   USED_PERCENT_THRESHOLD - the value of -t|--threshold argument
# Arguments:
#   $@ (array) - the script's arguments
#######################################################################
parse_cmdline() {
  # Global variables
  declare -g DEVICE_NAME USED_PERCENT_THRESHOLD PRUNE_VOLUMES
  PRUNE_VOLUMES="false"

  # Parser config
  declare argv
  argv=$(getopt -o 'd:t:v' --long 'device:,threshold:,volumes' -n "$(basename "$0")" -- "$@") || return
  eval "set -- $argv"

  for argv; do
    case $argv in
      -d | --device)
        shift
        DEVICE_NAME="$1"
        shift
        ;;
      -t | --threshold)
        shift
        USED_PERCENT_THRESHOLD="$1"
        ;;
      -v | --volumes)
        shift
        PRUNE_VOLUMES="true"
        ;;
      --)
        break
        ;;
    esac
  done
} # => parse_cmdline()

# Only run the script if not sourced, otherwise can be used the defined functions in the script
[[ ${BASH_SOURCE[0]} != "$0" ]] || main "$@"

exit 0
