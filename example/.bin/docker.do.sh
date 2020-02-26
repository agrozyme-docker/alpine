#!/bin/bash
set -euo pipefail

function copy_scripts() {
  local path="${1}"
  local bin=/opt/bin

  sudo mkdir -p "${bin}"
  sudo cp "${path}"/*.sh "${bin}"
  sudo chown root:root "${bin}"/*.sh
  sudo chmod +x "${bin}"/*.sh
}

function get_network() {
  echo "${DOCKER_NETWORK:-network}"
}

function check_network() {
  local network=$(get_network)
  local name=$(docker network ls -f name="${network}" --format '{{.Name}}')

  if [[ "${network}" == "${name}" ]]; then
    echo "${network}"
  else
    echo ""
  fi
}

function run_command() {
  local network=$(check_network)
  local user=$(id -u)
  local group=$(id -g)
  local attach=""

  if [[ "" != "${network}" ]]; then
    attach="--network=${network}"
  fi

  local run="docker run -it --rm -u=${user}:${group} ${attach} $@"
  ${run}
}

function setup_swarm() {
  local ip="${COREOS_PUBLIC_IPV4:-}"
  local active=$(docker info | grep -Po '(?<=^Swarm: ).*$')
  local address=""

  if [[ "" != "${ip}" ]]; then
    address="--advertise-addr ${ip}"
  fi

  local init="docker swarm init ${address}"

  if [[ "inactive" == "${active}" ]]; then
    ${init}
  fi

  local network=$(get_network)
  local exist=$(check_network)
  local create_network="docker network create --driver overlay --attachable ${network}"

  if [[ "" == "${exist}" ]]; then
    ${create_network}
  fi

  local attachable=$(docker network inspect "${network}" | grep -Po '(?<="Attachable": ).*(?=,)')

  if [[ "false" == "${attachable}" ]]; then
    echo y | docker network rm "${network}"
    sleep 1
    ${create_network}
  fi
}

function clean_swarm() {
  remove_all
  docker system prune -af
  sleep 1
  docker swarm leave -f
  sleep 1
  docker network prune -f
  sleep 1
}

function remove_all() {
  docker container prune -f
  sleep 1

  local stacks=($(docker stack ls --format "{{.Name}}"))

  if [[ 0 -eq ${#stacks[@]} ]]; then
    return
  fi

  docker stack rm "${stacks[@]}"
  sleep 1

  local items=($(docker ps -aq))

  if [[ 0 -ne ${#items[@]} ]]; then
    docker container stop "${items[@]}"
    sleep 1
  fi

  docker container prune -f
  sleep 1
}

function enable_swap() {
  local swap="$(dirname $(readlink -f ${BASH_SOURCE[0]}))/swap"

  if [[ ! -f "${swap}" ]]; then
    sudo fallocate -l 1G "${swap}"
  fi

  sudo chmod 600 "${swap}"
  sudo mkswap "${swap}"
  sudo swapon "${swap}"
}

function unit_content() {
  local file="${1}"
  cat << HEREDOC

[Unit]
Description=Docker Stack
After=docker.service
Requires=docker.service

[Service]
ExecStart=bash ${file}

[Install]
WantedBy=multi-user.target

HEREDOC
}

function update_unit() {
  if [[ ! -f "${2}" ]]; then
    return
  fi

  local unit="${1}"
  local content="$(unit_content ${2})"
  local path="/etc/systemd/system"
  local file="${path}/${unit}"

  sudo mkdir -p "${path}"
  sudo touch "${file}"
  echo -e "${content}" | sudo tee "${file}" > /dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable "${unit}"
}

function deploy() {
  local path="${1}"
  local name="$(basename ${path})"
  local setup="${path}/setup.sh"
  local compose="${path}/docker-compose.yml"
  local orchestrator=""

  if [[ "." == "${name:0:1}" ]]; then
    return
  fi

  if [[ -f "${compose}" ]]; then
    orchestrator="swarm"
  fi

  if [[ "" == "${orchestrator}" ]]; then
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
  local path="${1:-}"

  if [[ -z "${path}" ]]; then
    return
  fi

  local current="${PWD}"
  local items=($(find "${path}" -maxdepth 1 -mindepth 1 -type d))
  local item=""

  for item in "${items[@]}"; do
    cd "${item}"
    deploy "${item}"
  done

  cd "${current}"
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
