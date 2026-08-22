-- Keybindings Configuration
-- Reference: https://wiki.hypr.land/Configuring/Binds/

local mainMod = "SUPER"
local secondMod = "ALT"

----------------------
---- APP LAUNCHERS ---
----------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("~/.config/hypr/scripts/dropdown.sh"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(
	secondMod .. " + SPACE",
	hl.dsp.exec_cmd("qs ipc call shell toggleDashboard")
)

hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("hyprlock -c ~/.config/hypr/config/hyprlock.conf"))

hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/reload.sh"))
hl.bind(
	mainMod .. " + SHIFT + B",
	hl.dsp.exec_cmd("qs ipc call shell toggleBar")
)
-- Show keybinds cheat sheet
hl.bind(
	mainMod .. " + slash",
	hl.dsp.exec_cmd("qs ipc call shell toggleKeybinds")
)

----------------------------------
---- CLIPBOARD & NOTIFICATIONS ---
----------------------------------
-- for cliphist
hl.bind(
	mainMod .. " + V",
	hl.dsp.exec_cmd("qs ipc call shell toggleClipboard")
)
hl.bind(
	mainMod .. " + comma",
	hl.dsp.exec_cmd("qs ipc call shell toggleEmoji")
)
hl.bind(mainMod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe && notify-send 'Clipboard cleared'"))
hl.bind(
	mainMod .. " + N",
	hl.dsp.exec_cmd("qs ipc call shell toggleNotifications")
)

---------------------------
---- WINDOW MANAGEMENT ----
---------------------------

-- Basic Window Actions
hl.bind(mainMod .. " + X", hl.dsp.window.close())
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_float.py single"))
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.exec_cmd("~/.config/hypr/scripts/toggle_float.py all"))
hl.bind(mainMod .. " + backslash", hl.dsp.layout("togglesplit"))

-- Cycle & Move Focus
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
local altTabTimer = nil

local function checkAltReleased()
	if not hl.is_key_down("Alt_L") and not hl.is_key_down(64) and not hl.is_key_down("Alt_R") and not hl.is_key_down(108) then
		hl.exec_cmd("qs ipc call shell closeAltTab")
		altTabTimer = nil
	else
		altTabTimer = hl.timer(checkAltReleased, { type = "oneshot", timeout = 25 })
	end
end

hl.bind(
	secondMod .. " + Tab",
	function()
		hl.exec_cmd("qs ipc call shell toggleAltTab")
		if not altTabTimer then
			altTabTimer = hl.timer(checkAltReleased, { type = "oneshot", timeout = 25 })
		end
	end
)
hl.bind(
	secondMod .. " + SHIFT + Tab",
	function()
		hl.exec_cmd("qs ipc call shell toggleAltTab")
		if not altTabTimer then
			altTabTimer = hl.timer(checkAltReleased, { type = "oneshot", timeout = 25 })
		end
	end
)

-- Window Groups (Tabbed mode)
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
hl.bind(mainMod .. " + bracketright", hl.dsp.group.next())
hl.bind(mainMod .. " + bracketleft", hl.dsp.group.prev())
hl.bind(secondMod .. " + bracketright", hl.dsp.group.next())
hl.bind(secondMod .. " + bracketleft", hl.dsp.group.prev())

-- Focus Direction (Vim HJKL & Arrows)
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- Mouse Window Resize/Move
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

--------------------
---- WORKSPACES ----
--------------------
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))

-- Switch Workspaces
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Move Windows to Workspaces
for i = 1, 9 do
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Special Workspace (Scratchpad)
hl.bind(secondMod .. " + S", function()
	hl.config({ decoration = { dim_special = 0.65, blur = { special = true } } })
	hl.dispatch(hl.dsp.workspace.toggle_special("magic"))
end)
hl.bind(secondMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + SHIFT + Y", hl.dsp.window.move({ workspace = "+0" }))

-- Scroll Workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Resize Window (Vim HJKL & Arrows)
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.resize({ x = 0, y = -50, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.resize({ x = 0, y = 50, relative = true }), { repeating = true })

-- Move Window (Vim HJKL & Arrows)
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }))

------------------------
---- SYSTEM & MEDIA ----
------------------------

-- System Controls
hl.bind(
	mainMod .. " + SHIFT + W",
	hl.dsp.exec_cmd("qs ipc call shell toggleWallpaperSelector")
)
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("~/.config/hypr/scripts/shutdown.sh"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh -m region"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh -m window"))
hl.bind("PRINT", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh -m region"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh -m output"))

-- Volume & Brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ repeating = true, locked = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ repeating = true, locked = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })

-- Media Controls
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
