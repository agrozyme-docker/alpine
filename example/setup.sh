#!/bin/bash
set +e -uo pipefail

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local shell="${path}/.bin/docker.do.sh"
  sudo chmod +x "${path}"/*.sh
  source "${path}/profile.sh"
  ${shell} update_unit docker-stack.service "$(realpath ${source})"
  docker_setup_swarm
  docker_deploy_all
}

main "$@"
