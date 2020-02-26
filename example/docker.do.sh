#!/bin/bash
set -euo pipefail

function copy_scripts() {
  local path="${1:-}"

  if [[ ! -d "${path}" ]]; then
    return
  fi

  local bin="/opt/bin"
  sudo mkdir -p "${bin}"
  sudo cp "${path}"/*.sh "${bin}"
  sudo chown root:root "${bin}"/*.sh
  sudo chmod +x "${bin}"/*.sh
}

function source_path() {
  echo "$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
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

function enable_swap() {
  local swap="$(source_path)/swap"

  if [[ -f "${swap}" ]]; then
    return
  fi

  sudo fallocate -l 1G "${swap}"
  sudo chmod 600 "${swap}"
  sudo mkswap "${swap}"
  sudo swapon "${swap}"
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

[Service]
ExecStart=bash ${script}

[Install]
WantedBy=multi-user.target

HEREDOC
}

function update_unit() {
  local path="/etc/systemd/system"
  local unit="docker-stack.service"
  local file="${path}/${unit}"
  local script="$(source_path)/setup.sh"
  local content="$(unit_content ${script})"

  if [[ "" == "${content}" ]]; then
    return
  fi

  sudo mkdir -p "${path}"
  sudo touch "${file}"
  echo -e "${content}" | sudo tee "${file}" > /dev/null
  sudo systemctl daemon-reload
  sudo systemctl enable "${unit}"
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
