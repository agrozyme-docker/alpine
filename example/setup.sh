#!/bin/bash
set +e -uo pipefail

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local bin="${path}/.bin"
  local do="${bin}/docker.do.sh"
  sudo chmod +x "${bin}"/*.sh
  ${do} update_unit docker-stack.service "$(realpath ${source})"
  ${do} setup_swarm
  # ${do} enable_swap
  ${do} deploy_all "${path}"
}

main "$@"
