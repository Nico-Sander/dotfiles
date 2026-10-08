-- WezTerm config. Reloads automatically on save (or Ctrl+Shift+R).
-- Every option and its default: https://wezterm.org/config/lua/config/index.html
-- Inspect the live state with:
--   wezterm show-keys   all active key bindings
--   wezterm ls-fonts    which font files are actually used
--   Ctrl+Shift+L        debug overlay (Lua REPL + log)

local wezterm = require("wezterm")
local config = wezterm.config_builder() -- warns about typos / unknown options

-- ============================================================================
-- Startup
-- ============================================================================

-- Every window runs tmux, but only the first one attaches to the persistent
-- session "main". Each window opened later (Ctrl+Shift+N, or launching
-- WezTerm again while it runs) gets its own independent session.
--
--   first window   tmux new-session -A -s main
--                  -A attaches to "main" if it exists, otherwise creates it.
--                  Closing the window only detaches; "main" keeps running
--                  until reboot and is reattached on the next start.
--   later windows  tmux new-session -s <lowest free number: 1, 2, ...>
--                  destroy-unattached kills the session once no client shows
--                  it, so closing the window ends it like a normal terminal.
--                  It also ends if you switch that window to another session
--                  (prefix+s), since it is then unattached.
--
-- All sessions live on the same tmux server: prefix+s lists them, and
-- `tmux attach -t main` reaches "main" from any window.
-- Remove both lines to get a plain shell and start tmux by hand.
local tmux_main = { "tmux", "new-session", "-A", "-s", "main" }
-- Later windows name their session after the lowest free number (1, 2, ...).
-- tmux's own automatic names come from a counter that only ever increases,
-- so closing and reopening windows would give 1, 2, 3, ... 7 even with only
-- two sessions left. has-session -t "=N" matches the name N exactly.
config.default_prog = {
	"sh", "-c", [[
		n=1
		while tmux has-session -t "=$n" 2>/dev/null; do n=$((n + 1)); done
		exec tmux new-session -s "$n" \; set-option destroy-unattached on
	]],
}

-- gui-startup fires once, when the WezTerm process starts (not for later
-- windows). Spawn the first window on "main" and maximize it. A command given
-- on the command line (`wezterm start -- htop`) is kept instead.
wezterm.on("gui-startup", function(cmd)
	cmd = cmd or {}
	cmd.args = cmd.args or tmux_main
	local _, _, window = wezterm.mux.spawn_window(cmd)
	window:gui_window():maximize()
end)

-- ============================================================================
-- Keys
-- ============================================================================

-- Ctrl+Shift+N / Alt+n: new window in the directory of the tmux pane you are in.
-- WezTerm only sees the tmux client running in its window, not the shell
-- inside tmux, so it can't know that directory itself. Instead, ask tmux for
-- the active pane's path of the client attached to this window's tty.
-- The new tmux session starts in that directory because new-session uses
-- the client's working directory. Falls back to a plain new window if tmux
-- isn't running in this window.
local function spawn_window_in_tmux_cwd(window, pane)
	local cwd
	local tty = pane:get_tty_name()
	if tty then
		local ok, out = wezterm.run_child_process({
			"tmux", "display-message", "-p", "-c", tty, "#{pane_current_path}",
		})
		if ok and out ~= "" then
			cwd = out:gsub("%s+$", "")
		end
	end
	window:perform_action(wezterm.action.SpawnCommandInNewWindow({ cwd = cwd }), pane)
end

-- Alt+n does the same. WezTerm handles it before tmux/zsh/nvim see it, so
-- it can't be bound inside them anymore (currently unused everywhere).
config.keys = {
	{ key = "N", mods = "CTRL|SHIFT", action = wezterm.action_callback(spawn_window_in_tmux_cwd) },
	{ key = "n", mods = "ALT", action = wezterm.action_callback(spawn_window_in_tmux_cwd) },
}

-- Disable every default binding for WezTerm tabs and panes. tmux does both,
-- and with the tab bar off, a WezTerm tab or split would be invisible
-- (Ctrl+Shift+T would seem to replace the window with a new session).
-- This also frees Ctrl+Tab and Ctrl+PageUp/PageDown for tmux/nvim. Read from
-- WezTerm's own default list, so bindings added in future versions are
-- caught too (wezterm.gui is missing outside the GUI, e.g. in `wezterm cli`).
local tab_pane_actions = {
	SpawnTab = true, ActivateTab = true, ActivateTabRelative = true, MoveTabRelative = true,
	SplitHorizontal = true, SplitVertical = true, TogglePaneZoomState = true,
	ActivatePaneDirection = true, AdjustPaneSize = true,
}
if wezterm.gui then
	for _, k in ipairs(wezterm.gui.default_keys()) do
		local name = type(k.action) == "string" and k.action or next(k.action)
		if tab_pane_actions[name] then
			table.insert(config.keys, { key = k.key, mods = k.mods, action = wezterm.action.DisableDefaultAssignment })
		end
	end
end
-- Ctrl+Shift+W (close tab) stays: with one tab it closes the window.

-- Other default bindings that would swallow keys tmux/zsh/nvim could use.
-- Font size stays on Super+= / Super+- (Super+0 "reset" is taken by the
-- GNOME dock; use the command palette, Ctrl+Shift+P, "reset font size").
-- Ctrl+Shift+<key> combos map to the shifted character (Ctrl+_ etc.), so
-- those variants are freed as well.
local unbind = {
	{ "Enter", "ALT" }, -- ToggleFullScreen
	-- scroll WezTerm's own scrollback, which stays empty: tmux draws on the
	-- alternate screen and keeps the history itself
	{ "PageUp", "SHIFT" }, { "PageDown", "SHIFT" },
	{ "-", "CTRL" }, { "-", "SHIFT|CTRL" }, { "_", "CTRL" }, { "_", "SHIFT|CTRL" }, -- smaller
	{ "=", "CTRL" }, { "=", "SHIFT|CTRL" }, { "+", "CTRL" }, { "+", "SHIFT|CTRL" }, -- bigger
	{ "0", "CTRL" }, { "0", "SHIFT|CTRL" }, { ")", "CTRL" }, { ")", "SHIFT|CTRL" }, -- reset
}
for _, k in ipairs(unbind) do
	table.insert(config.keys, { key = k[1], mods = k[2], action = wezterm.action.DisableDefaultAssignment })
end

-- Useful defaults that stay:
--   Ctrl+Shift+Space   QuickSelect: labels hashes, URLs, paths, IPs on screen;
--                      type the label to copy it (Shift+label also pastes it)
--   Ctrl+Shift+C / V   copy / paste
--   Ctrl+Shift+F       search the screen
--   Ctrl+Shift+P       command palette
--   Ctrl+Shift+U       emoji / unicode picker
--   Ctrl+Shift+R       reload config

-- ============================================================================
-- Rendering
-- ============================================================================

-- Native Wayland is the default (enable_wayland = true). Set it to false to
-- run through XWayland instead, only as a fallback if the window misbehaves.
-- config.enable_wayland = false

-- GPU backend: "OpenGL" (default) | "WebGpu" (Vulkan on Linux) | "Software"
config.front_end = "WebGpu"

-- WezTerm checks GitHub for releases and shows a notification. The nightly is
-- updated through apt (apt.fury.io), so the check is just noise.
config.check_for_updates = false

-- ============================================================================
-- Window
-- ============================================================================

-- tmux provides tabs (windows) and its own status bar, so WezTerm's is off.
config.enable_tab_bar = false

-- "NONE"                   no title bar, no resize border
-- "RESIZE"                 no title bar, but resizable border
-- "TITLE | RESIZE"         title bar + resizable border (default)
-- "INTEGRATED_BUTTONS | RESIZE"  min/max/close buttons inside the tab bar
--
-- GNOME doesn't draw decorations for native Wayland apps, and WezTerm doesn't
-- draw its own title bar or border there either (tested on GNOME 50), so
-- TITLE and RESIZE have no effect. INTEGRATED_BUTTONS works, but needs the
-- tab bar. Only XWayland (enable_wayland = false) gets GNOME's title bar.
-- Window management goes through GNOME instead:
--   Super+left-drag    move          Super+f           toggle maximized
--   Super+right-drag   resize        Ctrl+Shift+drag   move (WezTerm)
config.window_decorations = "NONE"

-- Space between the window edge and the text grid, in pixels
-- (also accepts "0.5cell" or "1%").
config.window_padding = { left = 5, right = 5, top = 5, bottom = 5 }

-- ============================================================================
-- Font
-- ============================================================================

-- WezTerm ships JetBrains Mono, "Symbols Nerd Font Mono" (all Nerd Font icons)
-- and Noto Color Emoji as built-in fallbacks, so no fonts have to be installed
-- and any glyph missing from the main font is still found.
-- To use another font, install it and list it with:
--   wezterm ls-fonts --list-system
-- weight: "Thin" | "ExtraLight" | "Light" | "Regular" | "Medium" | "DemiBold"
--         | "Bold" | "ExtraBold" | "Black"
config.font = wezterm.font("JetBrains Mono", { weight = "Medium" })
config.font_size = 12

-- JetBrains Mono has ligatures (-> == != render as single glyphs).
-- Uncomment to turn them off:
-- config.harfbuzz_features = { "calt=0", "clig=0", "liga=0" }

-- ============================================================================
-- Colors & cursor
-- ============================================================================

-- Any built-in scheme works: https://wezterm.org/colorschemes/index.html
-- Tokyo Night variants: "Tokyo Night" | "Tokyo Night Storm" | "Tokyo Night Moon"
--                       | "Tokyo Night Day"
config.color_scheme = "Tokyo Night"

-- Overrides on top of the scheme. Inner programs that draw with the
-- "default" background (tmux status bar, nvim with a transparent theme)
-- show this color.
config.colors = {
	background = "#15161a",
}

-- 1.0 = opaque. Values < 1.0 make the window see-through (GNOME has no blur).
-- config.window_background_opacity = 0.95

-- Cursor shape before a program changes it. zsh/nvim/tmux can set their own
-- shape via escape codes, which overrides this.
-- "SteadyBlock" | "BlinkingBlock" | "SteadyUnderline" | "BlinkingUnderline"
-- | "SteadyBar" | "BlinkingBar"
config.default_cursor_style = "SteadyBlock"

-- ============================================================================
-- Mouse
-- ============================================================================

-- No custom bindings needed: by default, finishing a selection (drag,
-- double-click word, triple-click line) copies it to the clipboard *and*
-- the primary selection, and middle-click pastes the primary selection.
--
-- tmux owns the mouse (`mouse on`): WezTerm forwards all mouse events to it,
-- and tmux handles pane clicks, border resizing, scrolling and selection
-- (copied via wl-copy), or passes them on to nvim. Hold Shift to bypass tmux
-- and use WezTerm's own selection, e.g. across tmux panes. Shift+click on a
-- URL opens it in the browser.
-- GNOME's Super+drag (move/resize) is handled before WezTerm sees anything.

return config
