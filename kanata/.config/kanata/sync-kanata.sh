#!/bin/bash
# Copy the kanata config from the dotfiles to /etc/kanata and restart the service.
# The systemd service reads /etc/kanata/kanata-config.kbd (it can't read $HOME),
# so run this after every change to kanata.kbd.
# The config is validated first; an invalid config is never installed.
set -euo pipefail

SRC="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/kanata.kbd"
DST="/etc/kanata/kanata-config.kbd"
BIN="/usr/local/bin/kanata"
SERVICE="kanata.service"

notify() { command -v notify-send >/dev/null && notify-send "Kanata" "$1" -i input-keyboard || true; }

if [ ! -f "$SRC" ]; then
    echo "[ERROR] Config not found: $SRC" >&2
    exit 1
fi

# The binary is only executable by root and the kanata group, hence sudo.
echo "[INFO] Validating $SRC..."
if ! out="$(sudo "$BIN" --check --cfg "$SRC" 2>&1)"; then
    echo "$out" | grep -v '\[INFO\]' >&2
    echo "[ERROR] Config is invalid, nothing was changed." >&2
    notify "Config INVALID, not synced"
    exit 1
fi

if sudo cmp -s "$SRC" "$DST"; then
    echo "[INFO] $DST is already up to date, restarting anyway."
else
    echo "[INFO] Installing config to $DST..."
    sudo install -o root -g kanata -m 640 "$SRC" "$DST"
fi

sudo systemctl restart "$SERVICE"
sleep 0.5
if systemctl is-active --quiet "$SERVICE"; then
    echo "[INFO] $SERVICE restarted with the new config."
    notify "Config synced, service restarted"
else
    echo "[ERROR] $SERVICE failed to start. See: journalctl -u $SERVICE -n 30" >&2
    notify "Service FAILED to start"
    exit 1
fi
