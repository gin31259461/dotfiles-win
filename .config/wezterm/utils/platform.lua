local wezterm = require("module.wezterm")

local M = {}

local function is_found(str, pattern)
  return string.find(str, pattern) ~= nil
end

M.platform = function()
  return {
    is_win = is_found(wezterm.target_triple, "windows"),
    is_linux = is_found(wezterm.target_triple, "linux"),
    is_mac = is_found(wezterm.target_triple, "apple"),
  }
end

return M
