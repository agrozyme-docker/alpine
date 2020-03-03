# Summary

Alpine Base Image

# Packages

- su-exec
- tini
- curl
- luarocks
- busybox-suid

# Environment Variables

- DOCKER_CORE_UID
- DOCKER_CORE_GID
- DOCKER_STACK

# Core User

- Run the container with the `root` user
- Run the service in the container with the `core` user
- Simply map the host OS user by setting environment variables `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
  - default UID: `500`
  - default GID: `500`
- Use the `docker-core` module in the `docker-run.lua` script and call `update_user()` to change UID / GID of `core` using the environment variable `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
- If the service can not be run as a custom user, it can use `su-exec core` to execute the service

# Lua

- Replace shell scripts with lua scripts
  - lua (< 1MB) is small than bash (< 4MB)
  - lua has good data types and easy of use
  - lua has better errors and process handling
  - lua has a package manager (luarocks)
  - Use the lua standard libraries to avoid platform differences
- Use `luarocks install` to install lua package

# Docker Build

`Dockerfile` example

```dockerfile
FROM alpine
COPY rootfs /
RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
CMD ["/usr/local/bin/docker-run.lua"]
```

## /usr/local/bin/docker-build.lua

- The `docker build` script
- Add the statement `RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua` to `Dockerfile`

Example

```lua
#!/usr/bin/lua
local core = require("docker-core")

local function main()
  core.run("apk add --no-cache su-exec tini curl")
  core.run("mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh")
end

main()
```

# Docker Run

## /usr/local/bin/docker-run.lua

- The `docker run` script
- Add the statement `CMD ["/usr/local/bin/docker-run.lua"]` to `Dockerfile`

Example

```lua
#!/usr/bin/lua
local core = require("docker-core")

local function main()
  core.update_user()
  core.run("/bin/sh")
end

main()
```

## /usr/local/bin

- Put the command binary / script here
- Use `docker run -it --rm {image} {command}` to execute the command

## /usr/local/bin/module

- Put custom module scripts here
- Add the statement `local module = require("{module}")` to other scripts

## /usr/local/bin/module/docker-core.lua

- Some functions to help build docker images and start commands

# Host scripts

- Run at host OS or VM
- See `docker swarm` example in `host` folder

## Files Layout

```
/home/core/docker
|-- setup.sh
|-- profile.sh
|-- docker.do.sh
|-- other *.do.sh
|-- <subdirectory>
    |-- docker-compose.yml
    |-- setup.sh
```

## Prepare

- If the `core` user does not exist in the host OS, create one
- It is recommended to set the uid / gid of the `core` user to `500`
- The example files in the `host` folder need to be placed in the `/home/core/docker` directory
- The value of environment variable `DOCKER_STACK` is the subdirectory name and is passed to the container at runtime

## Deploy

- The `setup.sh` in the `/home/core/docker` is the main deployment script
- The `setup.sh` in the subdirectory will be executed before deploying the docker stack
- Change directory to `/home/core/docker` and run `/home/core/docker/setup.sh` to deploy the docker stacks

## \*.do.sh

- `docker.do.sh`: Implement functions for deploying docker stacks commands
- others: Implement the `setup_alias` function to set aliases for CLI commands
- Implement the `main` function to pass the first argument as the function name

Example

```bash
function source_file() {
  echo "$(readlink -f ${BASH_SOURCE[0]})"
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

function main() {
  local call="${1:-}"

  if [[ -z $(typeset -F "${call}") ]]; then
    return
  fi

  shift
  ${call} "$@"
}

main "$@"
```

## Commands

- profile: Rerun `profile.sh`
- docker_setup_swarm: Setup the docker swarm and network
- docker_clean_swarm: Clean everything up and leave the docker swarm
- docker_deploy_all: Delpoy all docker stacks
- docker_remove_all: Remove all docker stacks and containers
- docker_setup_unit: Setup the `docker-stack.service` service to run `/home/core/docker/setup.sh` at boot
- docker_clean_unit: Clean up the `docker-stack.service` service
