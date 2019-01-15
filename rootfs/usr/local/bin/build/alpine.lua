#!/usr/bin/lua

local function main()
  local core = require("docker-core")
  core.run("apk add --no-cache su-exec tini curl")
  core.run("mv /etc/profile.d/color_prompt /etc/profile.d/color_prompt.sh")
  core.update_user()
end

main()
