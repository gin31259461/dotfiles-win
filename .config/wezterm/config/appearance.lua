---@type Wezterm
---@diagnostic disable-next-line
local wezterm = require("wezterm")
local M = {}

M.apply = function(config)
  config.initial_cols = 120
  config.initial_rows = 40
  config.color_scheme = "Tokyo Night"
  config.font_size = 14
  config.font = wezterm.font_with_fallback({
    { family = "FiraCode Nerd Font", weight = "Regular", italic = false },
    { family = "FiraCode Nerd Font Mono", weight = "Regular", italic = false },
    { family = "Hack Nerd Font", weight = "Regular", italic = false },
  })
  config.window_close_confirmation = "NeverPrompt"
  config.window_decorations = "INTEGRATED_BUTTONS|RESIZE"
  config.use_fancy_tab_bar = false
  config.window_background_opacity = 0.9
  config.enable_scroll_bar = true
end

return M
