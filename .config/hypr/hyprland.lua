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
	-- Sync Wayland environment with systemd & D-Bus for screen sharing & portals
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

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
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("GDK_BACKEND", "wayland,x11,*")
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
