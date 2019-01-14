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
- use `core` user to run service which in container
- simple mapping host OS user by setting environment variables `DOCKER_CORE_UID` / `DOCKER_CORE_GID`
- default UID: 500
- default GID: 500
- use `docker-core.lua` and call `update_user()` to change user / group `core` with environment variable `DOCKER_CORE_UID` / `DOCKER_CORE_GID`

# Lua
- Use lua script to replace shell script
- use `luarocks install` to install lua package
- some function to help build docker image and startup command in module `docker-core.lua`

# Script Paths
- /usr/local/bin
  - put `CMD` script here
  - in `Dockerfile` add statement `CMD ["/usr/local/bin/{command}.lua"]`
- /usr/local/bin/build
  - put `docker build` script here
  - in `Dockerfile` add statement `RUN lua /usr/local/bin/build/{build}.lua`
- /usr/local/bin/module
  - put module scripts here
  - in other script file add statement `local module = require("{module}")` to use.
