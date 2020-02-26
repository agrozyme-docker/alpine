#!/bin/bash
set +e -uo pipefail

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local profile="${path}/profile.sh"
  local run="${path}/docker.do.sh"
  sudo chmod +x "${path}"/*.sh

  if [[ -r "${profile}" ]]; then
    source "${profile}"
  fi

  if [[ -r "${run}" ]]; then
    ${run} update_unit
    ${run} setup_swarm
    ${run} deploy_all
  fi
}

main "$@"
