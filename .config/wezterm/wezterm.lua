-- Pull in the WezTerm API
local wezterm = require("wezterm")
local mux = wezterm.mux
local act = wezterm.action

-- ============================================================================
-- Startup Events
-- ============================================================================

-- Maximize the window automatically when WezTerm starts
wezterm.on("gui-startup", function(cmd)
	local _, _, window = mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()
	gui_window:maximize()
end)

-- Initialize the configuration builder
local config = wezterm.config_builder()

-- ============================================================================
-- Core & Performance Settings
-- ============================================================================

-- Disable native Wayland to prevent "not responding" freezes on Ubuntu 24.04
config.enable_wayland = false

-- Specify the rendering backend to smooth out Neovim scrolling
-- (If WebGpu causes graphical glitches, change this to "OpenGL")
config.front_end = "WebGpu"

-- Launch tmux automatically, attachin to 'main' or creating it
config.default_prog = { "tmux", "new-session", "-A", "-s", "main" }

-- ============================================================================
-- Window Appearance & UI
-- ============================================================================

config.initial_cols = 120
config.initial_rows = 28
config.enable_tab_bar = false -- Change this to enable the tab bar
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.enable_scroll_bar = false
config.window_decorations = "NONE"

-- Uniform padding around the edges of the terminal
config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

-- ============================================================================
-- Fonts & Colors
-- ============================================================================

--config.font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Medium", italic = false })
config.font = wezterm.font("JetBrainsMonoNL Nerd Font", { weight = "Medium", italic = false })
config.font_size = 12
config.color_scheme = "Tokyo Night"

-- Custom color overrides
config.colors = {
	background = "#15161a",
}

config.window_background_opacity = 1.0
config.macos_window_background_blur = 20
config.default_cursor_style = "SteadyBlock"

-- ============================================================================
-- Mouse Settings
-- ============================================================================
config.mouse_bindings = {
	-- Left click drag / release: copy selection to clipboard upon release
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelectionOrOpenLinkAtMouseCursor("ClipboardAndPrimarySelection"),
	},
	-- Double-click to select word and copy to clipboard
	{
		event = { Up = { streak = 2, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},
	-- Triple-click to select full line and copy to clipboard
	{
		event = { Up = { streak = 3, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("ClipboardAndPrimarySelection"),
	},
}

-- Finally, return the configuration to WezTerm
return config
