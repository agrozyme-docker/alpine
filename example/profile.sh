#!/bin/bash

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local bin="${path}/.bin"
  local shell
  declare -A shell=(
    ['docker']="${bin}/docker.do.sh"
  )

  sudo chmod +x "${bin}/*"
  alias profile="source ${source}"

  alias docker_setup_swarm="${shell['docker']} setup_swarm"
  alias docker_clean_swarm="${shell['docker']} clean_swarm"
  alias docker_deploy_all="${shell['docker']} deploy_all ${path}"
  alias docker_remove_all="${shell['docker']} remove_all"
}

main "$@"
