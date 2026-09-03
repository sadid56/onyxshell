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
terminal = os.getenv("TERMINAL") or "kitty"
fileManager = terminal .. " --class yazi -e yazi"
browser = os.getenv("BROWSER") or "brave-origin"
hl.env("TERMINAL", terminal)

-------------------
---- AUTOSTART ----
-------------------
hl.on("hyprland.start", function()
	hl.exec_cmd("qs")
	hl.exec_cmd("hypridle -c ~/.config/hypr/config/hypridle.conf")
	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")
	hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
	hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
hl.env("QS_CONFIG_PATH", (os.getenv("HOME") or "/home/sadid") .. "/.config/qs")
hl.env("GTK_THEME", "Adwaita:dark")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("GDK_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("MALLOC_TRIM_THRESHOLD_", "131072")
hl.env("MALLOC_ARENA_MAX", "2")
hl.env("ROUNDED", "20")

------------------------
---- IMPORT MODULES ----
------------------------
package.loaded["lua.keybinds"] = nil
package.loaded["lua.windowrules"] = nil
package.loaded["lua.settings"] = nil
package.loaded["lua.input"] = nil
package.loaded["lua.animation"] = nil
package.loaded["theme.colors"] = nil

require("lua.keybinds")
require("lua.windowrules")
require("lua.settings")
require("lua.input")
require("lua.animation")
