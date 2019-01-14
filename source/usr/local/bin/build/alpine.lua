#!/usr/bin/lua

local function main()
  local core = require("docker-core")
  core.run("apk add --no-cache bash rpm shadow su-exec tini curl")
  core.run("mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh")
  core.run("ln -sf /bin/bash /bin/sh")
  core.run("usermod -s /bin/sh root")
  core.run("addgroup -Sg 500 core")
  core.run("adduser -DHS -G core -g core -s /bin/sh -u 500 core")
end

main()
