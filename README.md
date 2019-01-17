# Summary
Alpine Base Image

# Packages
- su-exec
- tini
- curl
- luarocks

# Environment Variables
- DOCKER_CORE_UID
- DOCKER_CORE_GID

# Core User
- run the container with the `root` user
- run the service in the container with the `core` user
- simply map the host OS user by setting environment variables `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
- default UID: 500
- default GID: 500
- use the `docker-core` module in the `docker-run.lua` script and call `update_user()` to change UID / GID of `core` using the environment variable `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
- if the service can not be run as a custom user, it can use `su-exec core` to execute the service

# Lua
- replace shell scripts with lua scripts
  - lua (0.86MB) is small than bash (3.82MB)
  - lua has good data types and easy of use
  - lua has better errors and process handling
  - lua has a package manager (luarocks)
  - use the lua standard libraries to avoid platform differences
- use `luarocks install` to install lua package

## Scripts
### /usr/local/bin/module/docker-core.lua
- some functions to help build docker images and start commands

### /usr/local/bin/docker-build.lua
- `docker build` script
- add the statement `RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua` to `Dockerfile`

### /usr/local/bin/docker-run.lua
- `docker run` script
- add the statement `CMD ["/usr/local/bin/docker-run.lua"]` to `Dockerfile`

## Paths
### /usr/local/bin
- put command scripts here
- use `docker run -it --rm {image} {command}` to execute the script

### /usr/local/bin/module
- put custom module scripts here
- add the statement `local module = require("{module}")` to other scripts

## Examples

### Dockerfile
```dockerfile
FROM alpine
COPY rootfs /
RUN set +e -uxo pipefail && chmod +x /usr/local/bin/* && /usr/local/bin/docker-build.lua
CMD ["/usr/local/bin/docker-run.lua"]
```

### docker-build.lua
```lua
#!/usr/bin/lua
local core = require("docker-core")

local function main()
  core.run("apk add --no-cache su-exec tini curl")
  core.run("mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh")
end

main()
```

### docker-run.lua
```lua
#!/usr/bin/lua
local core = require("docker-core")

local function main()
  core.update_user()
  core.run("/bin/sh")
end

main()
```
