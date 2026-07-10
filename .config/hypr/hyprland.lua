-- Main Hyprland Lua Configuration
-- Reference: https://wiki.hypr.land/Configuring/Start/

------------------
---- MONITORS ----
------------------
hl.monitor({
    output   = "eDP-1",
    mode     = "1920x1080@144",
    position = "0x0",
    scale    = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
-- Defining globally so they can be accessed inside required submodules
terminal    = "kitty"
fileManager = "kitty -e yazi"
menu        = "rofi -show drun"
browser     = "brave"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function ()
    hl.exec_cmd("waybar")
    hl.exec_cmd("pypr")
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("qs -c overview")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("clipse -listen")
    hl.exec_cmd("gnome-keyring-deamon --start --components=secrets")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
    hl.exec_cmd("swaync")
    hl.exec_cmd("sleep 3 && ~/.config/hypr/scripts/notify-sequence.sh")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

------------------------
---- IMPORT MODULES ----
------------------------
require("appearance")
require("keybinds")
require("windowrules")
require("settings")
require("animation")
