#!/bin/bash
set +e -uo pipefail

function main() {
  local path="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
  local profile="${path}/profile.sh"
  local run="${path}/docker.do.sh"
  sudo chmod +x "${path}"/*.sh

  if [[ -f "${profile}" ]]; then
    source "${profile}"
  fi

  if [[ -f "${run}" ]]; then
    # ${run} update_unit
    ${run} setup_swarm
    ${run} deploy_all
  fi
}

main "$@"
