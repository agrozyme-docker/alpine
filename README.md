# Summary
Alpine Base Image

# Packages
- bash
- rpm
- shadow
- su-exec
- tini
- curl
- luarocks

# Environment Variables
- DOCKER_CORE_UID
- DOCKER_CORE_GID

# Custom Lua Module
- path: `/usr/local/bin/module`
- use: `require("docker-core.lua")`

# Note
- use `docker-core.lua` and call `update_user` to change user / group `core` with environment variable `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
