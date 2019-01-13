#!/usr/bin/env lua

local function main()
  local core = require "docker-core"
  -- core.run("apk add --no-cache bash rpm shadow su-exec tini curl lua5.3-posix")
  core.run("apk add --no-cache curl")
  core.run("mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh")
  -- core.run("ln -sf /bin/bash /bin/sh")
  core.run("addgroup -Sg 500 core")
  core.run("adduser -DHS -G core -g core -s /bin/sh -u 500 core")
  core.change_root()

  -- local grp = require "posix.grp"
  -- local group = getgrnam("core")

  -- local id = core.run("id -u core", true)
  -- print(id)

  -- core.run("luarocks install inspect")
  -- local inspect = require "inspect"
  -- print(inspect({a = 1, b = 2}))
end

main()
