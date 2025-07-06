local powershell = { label = "PowerShell", args = { "powershell.exe", "-NoLogo" } }
local zsh = { label = "Zsh", args = { "/bin/zsh", "-l" } }
local launch_menu = { powershell, zsh }

local M = {}

M.apply = function(config)
  local platform = require("utils.platform").platform()
  config.launch_menu = launch_menu

  if platform.is_win then
    config.default_prog = powershell.args
  else
    config.default_prog = zsh.args
  end
end

return M
