#! /usr/bin/env bash


# =========================================================
# Color Utils
# =========================================================

  RESET='\e[0m'
  BLACK='\e[1;30m'
    RED='\e[1;31m'
  GREEN='\e[1;32m'
 YELLOW='\e[0;33m'
   BLUE='\e[1;34m'
MAGENTA='\e[0;35m'
   CYAN='\e[1;36m'
   GRAY='\e[0;37m'

color() {
  printf "${1}${@:2}${RESET}"
}

c_red()     { color ${RED}      "$@"; }
c_green()   { color ${GREEN}    "$@"; }
c_magenta() { color ${MAGENTA}  "$@"; }
c_cyan()    { color ${CYAN}     "$@"; }
c_none()    { printf            "$@"; }


# =========================================================
# Task Utils
# =========================================================

_error_exit_trap() {
  local exit_code=$?
  test "${exit_code}" -eq 0 && pr_ok || pr_err
  exit "${exit_code}"
}

_elapsed_time() {
  local start=$1
  local elapsed=$(( $SECONDS - ${start} ))
  printf "%d:%.2d min" $(( ${elapsed} / 60 )) $(( ${elapsed} % 60 ))
}

pr_header() {
  local task=$1
  [ "$2" ] && local description=": ${2}"
  printf "[${CYAN}${task}${RESET}${description}]\n"
}

pr_task() {
  pr_header "$@"
  TASK_START_TIME=$SECONDS
  trap _error_exit_trap EXIT
}

pr_notify() {
  local color=$1
  local notify=$2
  trap - EXIT
  printf "[${color}${notify}${RESET}] ($(_elapsed_time $TASK_START_TIME))\n\n"
}

pr_ok()   { pr_notify $GREEN "pass" "$@"; }
pr_err()  { pr_notify $RED   "fail" "$@"; }

pr_run() {(
  pr_task "$@"
  shift
  "$@"
)}
