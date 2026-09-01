-----------------------------
---- INPUT & INTERACTION ----
-----------------------------
local follow_mouse = 1
local natural_scroll = true

-------------------
---- DEVICES ------
-------------------
hl.device({
	name = "elan07d2:00-04f3:321a-touchpad", 
	sensitivity = 0.8,
})

--------------------
---- GESTURES ------
--------------------
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.gesture({
	fingers = 3,
	direction = "up",
	action = function()
		hl.exec_cmd("qs ipc call shell toggleOverview")
	end,
})

hl.gesture({
	fingers = 3,
	direction = "down",
	action = function()
		hl.exec_cmd("qs ipc call shell toggleOverview")
	end,
})

hl.gesture({
	fingers = 4,
	direction = "up",
	action = function()
		hl.exec_cmd("qs ipc call shell toggleOverviewAll")
	end,
})

hl.gesture({
	fingers = 4,
	direction = "down",
	action = function()
		hl.exec_cmd("qs ipc call shell toggleOverviewAll")
	end,
})

-----------------------
---- CONFIGURATION ----
-----------------------
hl.config({
	input = {
		follow_mouse = follow_mouse,
		float_switch_override_focus = 0,
		mouse_refocus = true,
		touchpad = {
			natural_scroll = natural_scroll,
		},
	},

	cursor = {
		no_hardware_cursors = 0,
		no_warps = true,
		inactive_timeout = 5,
	},
})
