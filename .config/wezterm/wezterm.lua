-- ╭───────────────────────────────╮
-- │ 🚀 Main Config                │
-- ╰───────────────────────────────╯

local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Setup shell
--
local launch_menu = {}

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.term = "" -- Set to empty so FZF works on windows
  table.insert(launch_menu, {
    label = "PowerShell",
    args = { "powershell.exe", "-NoLogo" },
  })
  config.default_prog = { "powershell.exe", "-NoLogo" }
elseif wezterm.target_triple == "x86_64-unknown-linux-gnu" then
  table.insert(launch_menu, {
    label = "Zsh",
    args = { "/bin/zsh", "-l" },
  })
  config.default_prog = { "/bin/zsh", "-l" }
end

config.launch_menu = launch_menu
-- end

config.initial_cols = 120
config.initial_rows = 40

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("FiraCode Nerd Font", { weight = "Regular", italic = false })

-- ╭───────────────────────────────╮
-- │ 🚀 Event Function Controller  │
-- ╰───────────────────────────────╯

-- initial screen
-- read current screen
local position_file_path = wezterm.home_dir .. "/.wezterm_position"
local file, err = io.open(position_file_path, "r")
local current_screen

if not file then
  current_screen = ""
else
  current_screen = file:read("*all")
end

-- initial window using event listener
wezterm.on("gui-startup", function(cmd)
  -- find name of display screen
  local screen
  local screens = wezterm.gui.screens().by_name
  for name_tmp, screen_tmp in pairs(screens) do
    if name_tmp == current_screen then
      current_screen = name_tmp
      screen = screen_tmp
    end
  end

  if screen == nil then
    screen = wezterm.gui.screens().main
  end

  -- setting window size

  -- local ratio = 0.7
  -- local width, height = screen.width * ratio, screen.height * ratio

  local width, height = 1280, 720 -- px
  local tab, pane, window = wezterm.mux.spawn_window(cmd or {
    position = {
      x = (screen.width - width) / 2,
      y = (screen.height - height) / 2 * 0.8, -- 讓窗口稍微往上一點比較爽
      origin = { Named = screen.name },
    },
  })
  window:gui_window():set_inner_size(width, height) -- px
end)

return config
