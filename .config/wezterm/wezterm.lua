local wezterm = require("wezterm")

local config = wezterm.config_builder()

-- Setup shell
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

config.initial_cols = 150
config.initial_rows = 40
config.color_scheme = "Tokyo Night"
config.font = wezterm.font("FiraCode Nerd Font")

return config
