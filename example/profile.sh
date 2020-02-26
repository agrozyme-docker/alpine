#!/bin/bash

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local docker_do="${path}/docker.do.sh"

  sudo chmod +x "${path}"/*.sh
  alias profile="source ${source}"

  alias docker_setup_swarm="${docker_do} setup_swarm"
  alias docker_clean_swarm="${docker_do} clean_swarm"
  alias docker_deploy_all="${docker_do} deploy_all"
  alias docker_remove_all="${docker_do} remove_all"
}

main "$@"
