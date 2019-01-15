local M = {}

local function color(text, code)
  local escape = string.char(27)
  local prefix = escape .. "[" .. code .. "m"
  local suffix = escape .. "[0m"
  return prefix .. text .. suffix
end

function M.error(...)
  local code = "31"
  local text = string.format(...)
  print(color(text, code))
end

function M.warn(...)
  local code = "33"
  local text = string.format(...)
  print(color(text, code))
end

function M.info(...)
  local code = "32"
  local text = string.format(...)
  print(color(text, code))
end

function M.debug(...)
  local list = {...}
  local total = #list
  local items = {"@ ", debug.getinfo(2, "n").name, "("}

  for index, item in pairs(list) do
    if ("string" == type(item)) then
      item = '"' .. item .. '"'
    end

    items[#items + 1] = tostring(item)

    if (index < total) then
      items[#items + 1] = ", "
    end
  end

  items[#items + 1] = ")"
  M.info(table.concat(items))
end

function M.capture_raw(...)
  local command = string.format(...)
  local file = assert(io.popen(command, "r"))
  local text = assert(file:read("*a"))
  file:close()
  return text
end

function M.capture(...)
  return M.capture_raw(...):gsub("^%s+", ""):gsub("%s+$", ""):gsub("[\n\r]+", " ")
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

function M.run(...)
  local command = string.format(...)
  M.info("+ %s", command)
  return M.execute(command)
end

function M.getenv(name, default)
  return os.getenv(name) or default
end

function M.get_env_table(items)
  local result = {}

  for index, item in pairs(items) do
    result[index] = M.getenv(index, item)
  end

  return result
end

function M.update_user()
  local item = M.get_env_table({DOCKER_CORE_UID = 500, DOCKER_CORE_GID = 500})
  os.execute("deluser core")
  os.execute("delgroup core")
  M.execute("addgroup -Sg 500 core")
  M.execute("adduser -DHS -G core -g core -s /bin/sh -u 500 core")
end

function M.chown(...)
  for _, item in pairs({...}) do
    if (M.test("-e %s", item)) then
      M.execute("chown -R core:core %s", item)
    end
  end
end

function M.mkdir(...)
  for _, item in pairs({...}) do
    if (M.test("! -e %s", item)) then
      M.execute("mkdir -p %s", item)
    end

    M.chown(item)
  end
end

function M.clear_path(...)
  for _, item in pairs({...}) do
    if (M.test("-z %s", item)) then
      M.chown(item)
    else
      M.execute("rm -rf %s", item)
      M.mkdir(item)
    end
  end
end

function M.read_file(name)
  local file = assert(io.open(name, "r"))
  local text = file:read("a")
  file:close()
  return text
end

function M.write_file(name, ...)
  local file = assert(io.open(name, "w"))
  file:write(...)
  file:flush()
  return file:close()
end

function M.append_file(name, ...)
  local file = assert(io.open(name, "a"))
  file:write(...)
  file:flush()
  return file:close()
end

function M.replace_file(target, backup)
  local index = target:find("/", -1, true)
  local path = target:sup(1, index)
  local file = target:sup(index + 1)
  local options = ""

  if (backup) then
    options = "-b --suffix=." .. backup
  end

  local source = path .. "." .. file
  M.run("mv -f %s %s %s", options, source, target)
end

return M
