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

config.initial_cols = 120
config.initial_rows = 28
config.enable_tab_bar = false
config.window_padding = {
	left = 4,
	right = 0,
	top = 0,
	bottom = 0,
}
config.enable_scroll_bar = false
config.window_decorations = "RESIZE"
config.integrated_title_button_style = "Gnome"

-- or, changing the font size and color scheme.
config.font = wezterm.font("JetBrains Mono", { weight = "Medium", italic = true })
config.font_size = 12
config.color_scheme = "Tokyo Night"
config.window_background_opacity = 1.0
config.default_cursor_style = "BlinkingBar"

-- Finally, return the configuration to wezterm:
return config
