local M = {}

local function color(text, code)
  local prefix = string.char(27) .. "[" .. code .. "m"
  local suffix = string.char(27) .. "[0m"
  return prefix .. text .. suffix
end

function M.error(text)
  local code = "31"
  print(color(text, code))
end

function M.warn(text)
  local code = "33"
  print(color(text, code))
end

function M.info(text)
  local code = "32"
  print(color(text, code))
end

function M.capture(command, raw)
  local file = assert(io.popen(command, "r"))
  local text = assert(file:read("*a"))
  file:close()

  if (raw) then
    return text
  end

  return text:gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\n\r]+", " ")
end

function M.run(command, silent)
  local silent = silent or false

  if (false == silent) then
    M.info("+ " .. command)
  end

  local _, text = assert(os.execute(command))
  return text
end

function M.getenv(name, default)
  return os.getenv(name) or default
end

function M.update_core_user()
  M.info("@ " .. debug.getinfo(1, "n").name)

  local user = {
    uid = M.getenv("DOCKER_CORE_UID", M.capture("id -u core")),
    gid = M.getenv("DOCKER_CORE_GID", M.capture("id -g core"))
  }

  M.run(string.format("groupmod -g %s core", user.gid), true)
  M.run(string.format("usermod -u %s core", user.uid), true)
end

return M
