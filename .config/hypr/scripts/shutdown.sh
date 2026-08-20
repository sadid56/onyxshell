#!/bin/bash

hyprctl clients -j | jq -r '.[].address' | while read -r addr; do
  hyprctl dispatch closewindow address:$addr
done

sleep 2

systemctl poweroff
