#!/bin/bash
set -euo pipefail

function source_file() {
  echo "$(readlink -f ${BASH_SOURCE[0]})"
}

function source_path() {
  echo "$(dirname $(source_file))"
}

function setup_alias() {
  local run="$(source_file)"

  alias docker_setup_swarm="${run} setup_swarm"
  alias docker_clean_swarm="${run} clean_swarm"
  alias docker_deploy_all="${run} deploy_all"
  alias docker_remove_all="${run} remove_all"
  alias docker_setup_unit="${run} setup_unit"
  alias docker_clean_unit="${run} clean_unit"
}

function get_network() {
  echo "${DOCKER_NETWORK:-network}"
}

function check_network() {
  local network="$(get_network)"
  local name="$(docker network ls -f name=${network} --format '{{.Name}}')"

  if [[ "${network}" == "${name}" ]]; then
    echo "${network}"
  else
    echo ""
  fi
}

function run_command() {
  local network="$(check_network)"
  local user="$(id -u):$(id -g)"
  local attach=""

  if [[ "" != "${network}" ]]; then
    attach="--network=${network}"
  fi

  local run="docker run -it --rm -u=${user} ${attach} $@"
  ${run}
}

function unit_content() {
  local script="${1:-}"

  if [[ ! -f "${script}" ]]; then
    echo ""
    return
  fi

  cat << HEREDOC

[Unit]
Description=Docker Stack
After=docker.service
Requires=docker.service
ConditionPathExists=${script}

[Service]
Type=oneshot
ExecStart=bash ${script}

[Install]
WantedBy=multi-user.target

HEREDOC
}

function unit_path() {
  echo "/etc/systemd/system"
}

function unit_name() {
  echo "docker-stack.service"
}

function setup_unit() {
  local path="$(unit_path)"
  local name="$(unit_name)"
  local file="${path}/${name}"
  local script="$(source_path)/setup.sh"
  local content="$(unit_content ${script})"

  if [[ "" == "${content}" ]]; then
    return
  fi

  sudo mkdir -p "${path}"
  sudo touch "${file}"
  echo -e "${content}" | sudo tee "${file}" > /dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable "${name}"
}

function clean_unit() {
  local name="$(unit_name)"
  local file="$(unit_path)/${name}"
  set +e
  sudo systemctl disable "${name}" --now
  sudo rm -f "${file}"
  sudo systemctl daemon-reload
  set -e
}

function remove_all() {
  docker container prune -f
  local stacks=($(docker stack ls --format "{{.Name}}"))

  if [[ 0 -eq ${#stacks[@]} ]]; then
    return
  fi

  docker stack rm "${stacks[@]}"
  local items=($(docker ps -aq))

  if [[ 0 -ne ${#items[@]} ]]; then
    docker container stop "${items[@]}"
  fi

  docker container prune -f
}

function deploy_stack() {
  local path="${1:-}"

  if [[ ! -d "${path}" ]]; then
    return
  fi

  local setup="${path}/setup.sh"
  local compose="${path}/docker-compose.yml"
  local name="$(basename ${path})"

  if [[ "." == "${name:0:1}" ]]; then
    return
  fi

  if [[ ! -f "${compose}" ]]; then
    return
  fi

  if [[ -f "${setup}" ]]; then
    bash "${setup}"
  fi

  set +e
  DOCKER_STACK="${name}" docker stack deploy -c "${compose}" "${name}"
  set -e
}

function deploy_all() {
  local current="${PWD}"
  local path="$(source_path)"
  local items=($(find "${path}" -maxdepth 1 -mindepth 1 -type d))
  local item=""

  for item in "${items[@]}"; do
    cd "${item}"
    deploy_stack "${item}"
  done

  cd "${current}"
}

function clean_swarm() {
  remove_all
  docker swarm leave -f
  docker system prune -af
}

function setup_swarm() {
  local ip="${COREOS_PUBLIC_IPV4:-}"
  local active="$(docker info | grep -Po '(?<=^Swarm: ).*$')"
  local address=""

  if [[ "" != "${ip}" ]]; then
    address="--advertise-addr ${ip}"
  fi

  local init="docker swarm init ${address}"

  if [[ "inactive" == "${active}" ]]; then
    ${init}
  fi

  local network="$(get_network)"
  local check_network="$(check_network)"
  local create_network="docker network create --driver overlay --attachable ${network}"

  if [[ "" == "${check_network}" ]]; then
    ${create_network}
  fi

  local attachable="$(docker network inspect ${network} | grep -Po '(?<="Attachable": ).*(?=,)')"

  if [[ "false" == "${attachable}" ]]; then
    echo y | docker network rm "${network}"
    sleep 1
    ${create_network}
  fi
}

function main() {
  local call="${1:-}"

  if [[ -z $(typeset -F "${call}") ]]; then
    return
  fi

  shift
  ${call} "$@"
}

main "$@"
