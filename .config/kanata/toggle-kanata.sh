#!/bin/bash
SERVICE="kanata.service"

if systemctl is-active --quiet "$SERVICE"; then
    systemctl stop "$SERVICE"
    # Send a notification (optional, requires libnotify-bin)
    notify-send "Kanata" "Service STOPPED" -i input-keyboard
else
    systemctl start "$SERVICE"
    notify-send "Kanata" "Service STARTED" -i input-keyboard
fi
