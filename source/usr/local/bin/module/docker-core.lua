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

function M.test(...)
  local command = "test " .. string.format(...)
  return os.execute(command)
end

function M.execute(...)
  local command = string.format(...)
  local _, text = assert(os.execute(command))
  return text
end

function M.run(command, silent)
  local silent = silent or false

  if (false == silent) then
    M.info("+ " .. command)
  end

  return M.execute(command)
end

function M.getenv(name, default)
  return os.getenv(name) or default
end

local function join(list, separator)
  local total = #list
  local items = {}

  for index, item in pairs(list) do
    if ("string" == type(item)) then
      item = '"' .. item .. '"'
    end

    table.insert(items, tostring(item))

    if (index < total) then
      table.insert(items, separator)
    end
  end

  return table.concat(items)
end

local function info(name, ...)
  M.info("@ " .. name .. "(" .. join({...}, ", ") .. ")")
end

function M.updateUser()
  local name = debug.getinfo(1, "n").name
  info(name)

  local user = {
    uid = M.getenv("DOCKER_CORE_UID", M.capture("id -u core")),
    gid = M.getenv("DOCKER_CORE_GID", M.capture("id -g core"))
  }

  M.run(string.format("groupmod -g %s core", user.gid), true)
  M.run(string.format("usermod -u %s core", user.uid), true)
end

function M.clearPath(...)
  local handler = function(item)
    if (M.test("-z %s", item)) then
      return
    end

    M.execute("rm -rf %s", item)
    M.execute("mkdir -p %s", item)
    M.execute("chown -R core:core %s", item)
  end

  local name = debug.getinfo(1, "n").name
  info(name, ...)

  for _, item in pairs({...}) do
    handler(item)
  end
end

return M
