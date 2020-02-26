#!/bin/bash

function main() {
  local source="$(readlink -f ${BASH_SOURCE[0]})"
  local path="$(dirname ${source})"
  local do="${path}/docker.do.sh"

  alias profile="source ${source}"
}

main "$@"
