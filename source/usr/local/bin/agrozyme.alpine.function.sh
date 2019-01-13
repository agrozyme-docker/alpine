#!/bin/bash
set -euo pipefail

function change_core() {
  local old_uid=$(id -u core)
  local old_gid=$(id -g core)
  local new_uid=${DOCKER_CORE_UID:-${old_uid}}
  local new_gid=${DOCKER_CORE_GID:-${old_gid}}
  groupmod -g "${new_gid}" core
  usermod -u "${new_uid}" core
}

function make_folder() {
  local folder=${1:-}

  if [[ -z "${folder}" ]]; then
    return
  fi

  mkdir -p "${folder}"
  chown -R core:core "${folder}"
  shift
  make_folder "$@"
}

function empty_folder() {
  local folder=${1:-}

  if [[ -z "${folder}" ]]; then
    return
  fi

  rm -rf "${folder}"
  make_folder "${folder}"
  shift
  empty_folder "$@"
}

function main() {
  local call=${1:-}

  if [[ -z $(typeset -F "${call}") ]]; then
    return
  fi

  shift
  ${call} "$@"
}

main "$@"
