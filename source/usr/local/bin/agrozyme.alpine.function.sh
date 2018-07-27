#!/bin/bash
set -euo pipefail

function change_core() {
  local old_uid=$(id -u core)
  local old_gid=$(id -g core)
  local new_uid=${DOCKER_UID:-${old_uid}}
  local new_gid=${DOCKER_GID:-${old_gid}}
  groupmod -g "${new_gid}" core
  usermod -u "${new_uid}" core
  # find / -group "${old_gid}" -exec chgrp -h core {} \;
  # find / -user "${old_uid}" -exec chown -h core {} \;
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
