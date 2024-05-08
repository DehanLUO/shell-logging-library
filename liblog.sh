#!/bin/bash
#
# Enhanced logging library with configurable log levels and timestamp
# Usage:
#   LIBLOG_LOG_LEVEL=1; source liblog.sh
# Author:
#   Dehan

# Log level definitions
readonly LIBLOG_CASE_LOG_LEVEL_DEBUG=0
readonly LIBLOG_CASE_LOG_LEVEL_INFO=1
readonly LIBLOG_CASE_LOG_LEVEL_WARN=2
readonly LIBLOG_CASE_LOG_LEVEL_ERROR=3

# Date format definitions
readonly LIBLOG_CASE_DATE_FORMAT_MILLISECOND=0
readonly LIBLOG_CASE_DATE_FORMAT_SECOND=1

# Stack identifiers for message processing
readonly LIBLOG_MESSAGE_STACK_LOG_LEVEL=0
readonly LIBLOG_MESSAGE_STACK_DATE_EXEC=1

# Color setup using tput, with safety checks
LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_RED="$(tput setaf 1 2> /dev/null || echo '')"
LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_GREEN="$(tput setaf 2 2> /dev/null || echo '')"
LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_YELLOW="$(tput setaf 3 2> /dev/null || echo '')"
LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_DEFAULT="$(tput sgr0 2> /dev/null || echo '')"
readonly LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_RED
readonly LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_GREEN
readonly LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_YELLOW
readonly LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_DEFAULT

# Initialization of global variables
LIBLOG_STDOUT_FILENAME=""
LIBLOG_STDOUT_LINENO=""
LIBLOG_STDOUT_FUNCNAME=""
LIBLOG_STDOUT_LEVEL=""

#######################################
# Initializes the logging library.
# Checks for necessary command availability and sets defaults.
# Globals:
#   LIBLOG_CASE_LOG_LEVEL_DEBUG
#   LIBLOG_CASE_LOG_LEVEL_INFO
#   LIBLOG_CASE_LOG_LEVEL_WARN
#   LIBLOG_CASE_LOG_LEVEL_ERROR
#   LIBLOG_CASE_DATE_FORMAT_MILLISECOND
#   LIBLOG_CASE_DATE_FORMAT_SECOND
#   LIBLOG_MESSAGE_STACK_LOG_LEVEL
#   LIBLOG_MESSAGE_STACK_DATE_EXEC
#   LIBLOG_LOG_LEVEL
#   LIBLOG_DATE_EXEC
#   LIBLOG_DATE_FORMAT
#   LIBLOG_DATE_FLAGS_TIMESTAMP
#   LIBLOG_DATE_FLAGS_RUNTIME
#######################################
function liblog::init() {
  local message_stack=""
  # Validate LIBLOG_LOG_LEVEL
  if [[ ! "${LIBLOG_LOG_LEVEL}" =~ ^[${LIBLOG_CASE_LOG_LEVEL_DEBUG}${LIBLOG_CASE_LOG_LEVEL_INFO}${LIBLOG_CASE_LOG_LEVEL_WARN}${LIBLOG_CASE_LOG_LEVEL_ERROR}]$ ]]; then
    LIBLOG_LOG_LEVEL="${LIBLOG_CASE_LOG_LEVEL_INFO}"
    message_stack+="${LIBLOG_MESSAGE_STACK_LOG_LEVEL}"
  fi
  readonly LIBLOG_LOG_LEVEL

  # Date command setup with robust checks
  if command -v gdate > /dev/null 2>&1; then
    readonly LIBLOG_DATE_EXEC="gdate"
  else
    readonly LIBLOG_DATE_EXEC="date" # Fallback to basic date functionality
  fi

  # Set date flags based on the available date command features
  if [[ "${LIBLOG_DATE_EXEC}" == "gdate" ]] || date "+%3N" &> /dev/null; then
    readonly LIBLOG_DATE_FLAGS_TIMESTAMP="+%Y-%m-%dT%H:%M:%S.%3N%z"
    readonly LIBLOG_DATE_FLAGS_RUNTIME="+%s%3N"
    readonly LIBLOG_DATE_FORMAT="${LIBLOG_CASE_DATE_FORMAT_MILLISECOND}"
  else
    readonly LIBLOG_DATE_FLAGS_TIMESTAMP="+%Y-%m-%dT%H:%M:%S%z"
    readonly LIBLOG_DATE_FLAGS_RUNTIME="+%s"
    readonly LIBLOG_DATE_FORMAT="${LIBLOG_CASE_DATE_FORMAT_SECOND}"
    message_stack+="${LIBLOG_MESSAGE_STACK_DATE_EXEC}"
  fi

  # Process any initial configuration errors
  liblog::process_message_stack "${message_stack}"
}

#######################################
# Processes the message stack to handle initial configuration errors
# Globals:
#   LIBLOG_LOG_LEVEL
#   LIBLOG_MESSAGE_STACK_LOG_LEVEL
#   LIBLOG_MESSAGE_STACK_DATE_EXEC
# Arguments:
#   message_stack
#######################################
function liblog::process_message_stack() {
  local message_stack="$1"
  while [ ${#message_stack} -gt 0 ]; do
    case "${message_stack:0:1}" in
      "${LIBLOG_MESSAGE_STACK_LOG_LEVEL}")
        liblog::warn "Invalid LIBLOG_LOG_LEVEL. Reset to INFO."
        ;;
      "${LIBLOG_MESSAGE_STACK_DATE_EXEC}")
        liblog::warn "Timestamp precision reduced to seconds."
        ;;
    esac
    message_stack=${message_stack:1}
  done
}

#######################################
# Change the output colour of echo
# Globals:
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_DEBUG
#   LIBLOG_CASE_LOG_LEVEL_INFO
#   LIBLOG_CASE_LOG_LEVEL_WARN
#   LIBLOG_CASE_LOG_LEVEL_ERROR
#   LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_RED
#   LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_GREEN
#   LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_YELLOW
#   LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_DEFAULT
# Arguments:
#   $@
# Outputs:
#   $@
#######################################
function liblog::echo() {
  case "${LIBLOG_STDOUT_LEVEL}" in
    "${LIBLOG_CASE_LOG_LEVEL_DEBUG}")
      echo "$@" >&1
      ;;
    "${LIBLOG_CASE_LOG_LEVEL_INFO}")
      echo -e "${LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_GREEN}$*" \
        "${LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_DEFAULT}" >&1
      ;;
    "${LIBLOG_CASE_LOG_LEVEL_WARN}")
      echo -e "${LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_YELLOW}$*" \
        "${LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_DEFAULT}" >&1
      ;;
    "${LIBLOG_CASE_LOG_LEVEL_ERROR}")
      echo -e "${LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_RED}$*" \
        "${LIBLOG_STDOUT_FOREGROUND_COLOR_ANSI_DEFAULT}" >&2
      ;;
    *) ;;
  esac
}

#######################################
# Prefix timestamp, level flag, function name, file name, and line number
# Globals:
#   LIBLOG_DATE_EXEC
#   LIBLOG_DATE_FLAGS_TIMESTAMP
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_DEBUG
#   LIBLOG_CASE_LOG_LEVEL_INFO
#   LIBLOG_CASE_LOG_LEVEL_WARN
#   LIBLOG_CASE_LOG_LEVEL_ERROR
#   LIBLOG_STDOUT_FUNCNAME
#   LIBLOG_STDOUT_FILENAME
#   LIBLOG_STDOUT_LINENO
# Arguments:
#   $@
# Outputs:
#   [stimestamp][flag][FUNC:function name][FILE:file name][LINE:line number] $*
#######################################
function libSTDOUT::strcat_header() {
  local string_cat
  string_cat="[$(${LIBLOG_DATE_EXEC} ${LIBLOG_DATE_FLAGS_TIMESTAMP})]"

  case "${LIBLOG_STDOUT_LEVEL}" in
    "${LIBLOG_CASE_LOG_LEVEL_DEBUG}") string_cat+="[D]" ;;
    "${LIBLOG_CASE_LOG_LEVEL_INFO}") string_cat+="[I]" ;;
    "${LIBLOG_CASE_LOG_LEVEL_WARN}") string_cat+="[W]" ;;
    "${LIBLOG_CASE_LOG_LEVEL_ERROR}") string_cat+="[E]" ;;
    *) ;;
  esac

  string_cat+="${LIBLOG_STDOUT_FUNCNAME:+"[FUNC:${LIBLOG_STDOUT_FUNCNAME}]"}"
  string_cat+="${LIBLOG_STDOUT_FILENAME:+"[FILE:${LIBLOG_STDOUT_FILENAME}]"}"
  string_cat+="${LIBLOG_STDOUT_LINENO:+"[LINE:${LIBLOG_STDOUT_LINENO}]"}"
  string_cat+="$*"

  echo "${string_cat}"
}

#######################################
# Standard debug output
# Globals:
#   LIBLOG_LOG_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_DEBUG
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_STDOUT_FUNCNAME
#   LIBLOG_STDOUT_FILENAME
#   LIBLOG_STDOUT_LINENO
# Arguments:
#   $*
# Useage:
#   liblog::debug "$*"
# Outputs:
#   [stimestamp][D][FUNC:function name][FILE:file name][LINE:line number] $*
#######################################
function liblog::debug() {
  if [ "${LIBLOG_CASE_LOG_LEVEL_DEBUG}" -lt "${LIBLOG_LOG_LEVEL}" ]; then
    return
  fi

  local LIBLOG_STDOUT_LEVEL="${LIBLOG_CASE_LOG_LEVEL_DEBUG}"
  local LIBLOG_STDOUT_FILENAME="${BASH_SOURCE[1]##*/}"
  local LIBLOG_STDOUT_LINENO="${BASH_LINENO[0]}"
  local LIBLOG_STDOUT_FUNCNAME="${FUNCNAME[1]}"

  liblog::echo "$(libSTDOUT::strcat_header "$*")"
}

#######################################
# Standard info output
# Globals:
#   LIBLOG_LOG_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_INFO
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_STDOUT_FUNCNAME
#   LIBLOG_STDOUT_FILENAME
#   LIBLOG_STDOUT_LINENO
# Arguments:
#   $*
# Useage:
#   liblog::info "$*"
# Outputs:
#   [stimestamp][I][FUNC:function name][FILE:file name][LINE:line number] $*
#######################################
function liblog::info() {
  if [ "${LIBLOG_CASE_LOG_LEVEL_INFO}" -lt "${LIBLOG_LOG_LEVEL}" ]; then
    return
  fi

  local LIBLOG_STDOUT_LEVEL="${LIBLOG_CASE_LOG_LEVEL_INFO}"
  local LIBLOG_STDOUT_FILENAME="${BASH_SOURCE[1]##*/}"
  local LIBLOG_STDOUT_LINENO="${BASH_LINENO[0]}"
  local LIBLOG_STDOUT_FUNCNAME="${FUNCNAME[1]}"

  liblog::echo "$(libSTDOUT::strcat_header "$*")"
}

#######################################
# Standard info output
# Globals:
#   LIBLOG_LOG_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_WARN
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_STDOUT_FUNCNAME
#   LIBLOG_STDOUT_FILENAME
#   LIBLOG_STDOUT_LINENO
# Arguments:
#   $*
# Useage:
#   liblog::warn "$*"
# Outputs:
#   [stimestamp][W][FUNC:function name][FILE:file name][LINE:line number] $*
#######################################
function liblog::warn() {
  if [ "${LIBLOG_CASE_LOG_LEVEL_WARN}" -lt "${LIBLOG_LOG_LEVEL}" ]; then
    return
  fi

  local LIBLOG_STDOUT_LEVEL="${LIBLOG_CASE_LOG_LEVEL_WARN}"
  local LIBLOG_STDOUT_FILENAME="${BASH_SOURCE[1]##*/}"
  local LIBLOG_STDOUT_LINENO="${BASH_LINENO[0]}"
  local LIBLOG_STDOUT_FUNCNAME="${FUNCNAME[1]}"

  liblog::echo "$(libSTDOUT::strcat_header "$*")"
}

#######################################
# Standard error output
# Globals:
#   LIBLOG_LOG_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_ERROR
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_STDOUT_FUNCNAME
#   LIBLOG_STDOUT_FILENAME
#   LIBLOG_STDOUT_LINENO
# Arguments:
#   $*
# Useage:
#   liblog::err "$*"
# Outputs:
#   [stimestamp][E][FUNC:function name][FILE:file name][LINE:line number] $*
#######################################
function liblog::err() {
  if [ "${LIBLOG_CASE_LOG_LEVEL_ERROR}" -lt "${LIBLOG_LOG_LEVEL}" ]; then
    return
  fi

  local LIBLOG_STDOUT_LEVEL="${LIBLOG_CASE_LOG_LEVEL_ERROR}"
  local LIBLOG_STDOUT_FILENAME="${BASH_SOURCE[1]##*/}"
  local LIBLOG_STDOUT_LINENO="${BASH_LINENO[0]}"
  local LIBLOG_STDOUT_FUNCNAME="${FUNCNAME[1]}"

  liblog::echo "$(libSTDOUT::strcat_header "$*")"
}

#######################################
# Handles the redirection of standard error output to log it using a specific log level
# Globals:
#   LIBLOG_STDOUT_LEVEL
#   LIBLOG_CASE_LOG_LEVEL_ERROR
# Usage:
#   exec 2> >(liblog::handle_stderr)
# Outputs:
#   Redirects and logs each line of stderr with error logging level
#######################################
function liblog::handle_stderr() {
  while IFS= read -r line; do
    local LIBLOG_STDOUT_LEVEL="${LIBLOG_CASE_LOG_LEVEL_ERROR}"
    liblog::echo "${line}"
  done
}

#######################################
# Main function for demonstrating the enhanced logging library
#######################################
function liblog::main() {
  set -E                                 # Enable inheriting of traps
  trap 'liblog::err "$BASH_COMMAND"' ERR # Set an error handler to capture and log any errors with the executed command
  exec 2> >(liblog::handle_stderr)       # Redirect standard error to a custom handler

  liblog::init

  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Shellscript is being run directly.
    liblog::debug "This is a debug log entry."
    liblog::info "This is an info log entry."
    liblog::warn "This is a warning log entry."
    liblog::err "This is an error log entry."
  fi
}

liblog::main
