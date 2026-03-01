-- Pull in the WezTerm API
local wezterm = require("wezterm")
local mux = wezterm.mux

-- Initialize the configuration builder
local config = wezterm.config_builder()

-- ============================================================================
-- Startup Events
-- ============================================================================

-- Maximize the window automatically when WezTerm starts
wezterm.on("gui-startup", function(cmd)
    local tab, pane, window = mux.spawn_window(cmd or {})
    local gui_window = window:gui_window()
    gui_window:maximize()
end)

-- ============================================================================
-- Core & Performance Settings
-- ============================================================================

-- Disable native Wayland to prevent "not responding" freezes on Ubuntu 24.04
config.enable_wayland = false

-- Specify the rendering backend to smooth out Neovim scrolling
-- (If WebGpu causes graphical glitches, change this to "OpenGL")
config.front_end = "WebGpu"

-- ============================================================================
-- Window Appearance & UI
-- ============================================================================

config.initial_cols = 120
config.initial_rows = 28
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.enable_scroll_bar = true
config.window_decorations = "RESIZE"

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

config.font = wezterm.font("CaskaydiaCove Nerd Font", { weight = "Medium", italic = false })
config.font_size = 12
config.color_scheme = "Tokyo Night"

-- Custom color overrides
config.colors = {
    background = "#131313",
}

config.window_background_opacity = 1.0
config.default_cursor_style = "BlinkingBar"

-- Finally, return the configuration to WezTerm
return config
