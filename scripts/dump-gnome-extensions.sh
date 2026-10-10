#!/bin/bash

# Save the GNOME Shell extension settings to gnome/extensions.dconf.
# Run after changing an extension's settings, then commit the result.
# populate.sh loads the file back with: dconf load /org/gnome/shell/extensions/

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$DOTFILES_DIR/gnome/extensions.dconf"

# dconf directories under /org/gnome/shell/extensions/ to keep. Everything
# else is left out, e.g. leftovers from removed extensions (p7-borders,
# tiling-assistant). dash-to-dock and ding belong to Ubuntu's built-in
# dock and desktop icons extensions.
KEEP_DIRS=(blur-my-shell dash-to-dock ding focus just-perfection multi-monitors-bar perfect-fit)

# Keep only the [sections] whose top-level directory is in KEEP_DIRS
_keep_sections() {
    awk -v keep="${KEEP_DIRS[*]}" '
        BEGIN { n = split(keep, k, " "); for (i = 1; i <= n; i++) want[k[i]] = 1 }
        /^\[/ { dir = substr($0, 2, length($0) - 2); sub(/\/.*/, "", dir); keep_it = (dir in want) }
        keep_it
    '
}

# Drop keys that extensions write as runtime state rather than settings,
# so they don't end up in the repo (stdin -> stdout).
_drop_runtime_keys() {
    grep -vE '^(rounded-blur-found|settings-version|available-indicators|monitor-indicator-catalog)=' || true
}

mkdir -p "$(dirname "$OUT")"
dconf dump /org/gnome/shell/extensions/ | _keep_sections | _drop_runtime_keys > "$OUT"
echo "Saved $(grep -c '^\[' "$OUT") sections to ${OUT#"$DOTFILES_DIR"/}"
