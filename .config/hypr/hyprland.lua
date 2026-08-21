
------------------
---- MONITORS ----
------------------
hl.monitor({
	output = "eDP-1",
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
terminal = "kitty"
fileManager = "nautilus"
browser = "brave-origin"

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("quickshell")
	hl.exec_cmd("hypridle -c ~/.config/hypr/config/hypridle.conf")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("systemctl --user start polkit-gnome-authentication-agent-1")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_LOGGING_RULES", "qt.svg.warning=false")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("ROUNDED", "16")


------------------------
---- IMPORT MODULES ----
------------------------
require("lua.keybinds")
require("lua.windowrules")
require("lua.settings")
require("lua.animation")
