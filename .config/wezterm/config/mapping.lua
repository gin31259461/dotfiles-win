local wezterm = require("wezterm")
local M = {}

M.apply = function(config)
  config.keys = {
    { key = "m", mods = "CTRL", action = wezterm.action.ShowLauncher },
    { key = "m", mods = "CTRL|ALT", action = wezterm.action.ShowTabNavigator },
    -- new window
    { key = "N", mods = "SHIFT|CTRL", action = wezterm.action.SpawnWindow },
    -- new tab
    { key = "T", mods = "SHIFT|CTRL", action = wezterm.action.ShowLauncher },
    -- show launch menu
    {
      key = "Enter",
      mods = "SHIFT|CTRL",
      action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|TABS|LAUNCH_MENU_ITEMS" }),
    },
    { key = "w", mods = "CTRL", action = wezterm.action.CloseCurrentTab({ confirm = false }) },
  }
end

return M
