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

function M.run(command, silent)
  local silent = silent or false

  if (false == silent) then
    M.info("+ " .. command)
  end

  local state, text = os.execute(command)

  if (state) then
    return text
  else
    M.error(text)
    os.exit(state)
  end
end

function M.getnev(name, default)
  return os.getnev(name) or default
end

function M.change_core()
end

return M
