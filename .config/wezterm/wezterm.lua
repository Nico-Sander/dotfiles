-- Pull in the wezterm API
local wezterm = require("wezterm")
local mux = wezterm.mux

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices.

-- For example, changing the initial geometry for new windows:
wezterm.on("gui-startup", function(window)
	local tab, pane, window = mux.spawn_window(cmd or {})
	local gui_window = window:gui_window()
	gui_window:maximize()
end)

-- config.term = "wezterm"

config.initial_cols = 120
config.initial_rows = 28
config.enable_tab_bar = false
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- config.enable_tab_bar = true
-- config.use_fancy_tab_bar = false

-- local border_color = "#208fe9" -- yaru-blue
--
-- config.window_frame = {
-- 	border_left_width = "2px",
-- 	border_right_width = "2px",
-- 	border_bottom_height = "2px",
-- 	border_top_height = "2px",
-- 	border_left_color = border_color,
-- 	border_right_color = border_color,
-- 	border_bottom_color = border_color,
-- 	border_top_color = border_color,
-- 	-- active_titlebar_bg = "none",
-- }

config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
-- config.integrated_title_button_style = "Gnome"

config.window_padding = {
	left = 5,
	right = 5,
	top = 5,
	bottom = 5,
}

-- or, changing the font size and color scheme.
config.font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Medium", italic = false })
config.font_size = 12
config.color_scheme = "Tokyo Night"
config.colors = {
	background = "#111111",
}
config.window_background_opacity = 1.0
config.default_cursor_style = "BlinkingBar"

-- Finally, return the configuration to wezterm:
return config
