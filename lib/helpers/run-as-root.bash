#! /usr/bin/env bash

if test "$(id -u)" -ne 0; then
  sudo -E "${0}" "${@}"
  exit $?
fi
