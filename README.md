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

# Lua
- build: use by `docker build`
  - path: `/usr/local/bin/build`
  - use: in `Dockerfile` add command `RUN lua /usr/local/bin/build/${image}.lua`
- module: use by build or other command
  - path: `/usr/local/bin/module`
  - use: `require("${module}")`

# Note
- use `/usr/local/bin/module/docker-core.lua` and call `update_user` to change user / group `core` with environment variable `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
