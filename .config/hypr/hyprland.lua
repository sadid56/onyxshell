------------------
---- MONITORS ----
------------------
hl.monitor({
	output = "",
	mode = "preferred",
	position = "auto",
	scale = 1,
})

---------------------
---- MY PROGRAMS ----
---------------------
terminal = "kitty"
fileManager = "kitty -e yazi"
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
	hl.exec_cmd("systemctl --user start hyprpolkitagent")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'")
end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("ROUNDED", "16")

------------------------
---- IMPORT MODULES ----
------------------------
require("lua.keybinds")
require("lua.windowrules")
require("lua.settings")
require("lua.animation")
