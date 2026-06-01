local wezterm = require("wezterm")
local helpers = require("helpers")
local act = wezterm.action
local config = wezterm.config_builder()

config.leader = { key = "Space", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	{ key = "o", mods = "CMD", action = helpers.open_url() },
	{ key = "LeftArrow", mods = "OPT", action = act.SendKey({ key = "b", mods = "ALT" }) },
	{ key = "RightArrow", mods = "OPT", action = act.SendKey({ key = "f", mods = "ALT" }) },
	{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "j", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
	{ key = "k", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "`", mods = "CMD", action = wezterm.action.TogglePaneZoomState },
	{ key = "Enter", mods = "CMD", action = wezterm.action.SplitPane({ direction = "Right" }) },
	{ key = "t", mods = "CMD", action = act.SwitchToWorkspace({ spawn = { cwd = wezterm.home_dir } }) },
	-- Vim-style pane navigation
	{ key = "h", mods = "CTRL", action = helpers.vim_aware_navigation("Left", "\x08") },
	{ key = "j", mods = "CTRL", action = helpers.vim_aware_navigation("Down", "\x0a") },
	{ key = "k", mods = "CTRL", action = helpers.vim_aware_navigation("Up", "\x0b") },
	{ key = "l", mods = "CTRL", action = helpers.vim_aware_navigation("Right", "\x0c") },
	{ key = "f", mods = "CTRL", action = helpers.manage_workspaces() },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = true }) },
}

-- General
config.font_size = 12.5
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.line_height = 1.15
config.cell_width = 0.9
config.window_padding = {
	left = 30,
	right = 30,
}
config.max_fps = 120
config.color_scheme = "Catppuccin Frappe"
config.colors = {
	foreground = "#FFFFFF",
	background = "#2B2B2B",
	split = "#383838",
	ansi = {
		"#1d1d1d", -- black (used as box bg by pi themes) 1d1d1d vs 1d1f21
		"#e78284", -- red
		"#a6d189", -- green
		"#e5c890", -- yellow
		"#8caaee", -- blue
		"#f4b8e4", -- magenta
		"#81c8be", -- cyan
		"#b5bfe2", -- white
	},
}
config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.8,
}

-- config.equalize_panes = true -- custom command, remove in official wezterm

config.enable_kitty_keyboard = true
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.notification_handling = "AlwaysShow"

return config
