#!/bin/bash
set +e -uo pipefail

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"

  sudo chmod +x "${path}"/*.sh
  alias profile="source ${source}"

  local items=($(find "${path}" -maxdepth 1 -mindepth 1 -type f -name '*.do.sh'))
  local item=""

  for item in "${items[@]}"; do
    source ${item} setup_alias
  done
}

main "$@"
