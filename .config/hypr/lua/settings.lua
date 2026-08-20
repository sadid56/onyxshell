local rounded = tonumber(os.getenv("ROUNDED")) or 16

local has_colors, colors = pcall(require, "theme.colors")
local active_col = (has_colors and colors.primary) and ("rgb(" .. colors.primary:gsub("#", "") .. ")") or "rgb(ffb3b4)"
local inactive_col = (has_colors and colors.outline_variant) and ("rgb(" .. colors.outline_variant:gsub("#", "") .. ")") or "rgb(574142)"
local group_active_col = (has_colors and colors.primary) and ("rgba(" .. colors.primary:gsub("#", "") .. "cc)") or "rgba(ffb3b4cc)"
local group_inactive_col = (has_colors and colors.outline_variant) and ("rgba(" .. colors.outline_variant:gsub("#", "") .. "55)") or "rgba(47464c55)"

hl.device({
	name = "elan07d2:00-04f3:321a-touchpad",
	sensitivity = 0.8,
})

hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 0,
		col = {
			active_border = active_col,
			inactive_border = inactive_col,
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	debug = {
		vfr = true,
	},

	decoration = {
		rounding = rounded,
		rounding_power = 2,
		active_opacity = 1.0,

		blur = {
			enabled = true,
			size = 5,
			passes = 3,
			vibrancy = 0.1696,
		},
	},

	input = {
		follow_mouse = 1,
		float_switch_override_focus = 2,
		mouse_refocus = false,
		touchpad = {
			natural_scroll = true,
		},
	},

	misc = {
		disable_hyprland_logo = false,
		on_focus_under_fullscreen = 1,
		focus_on_activate = true,
	},

	cursor = {
		no_hardware_cursors = 0,
	},

	group = {
		insert_after_current = true,
		col = {
			border_active = group_active_col,
			border_inactive = group_inactive_col,
			border_locked_active = group_active_col,
			border_locked_inactive = group_inactive_col,
		},
		groupbar = {
			enabled = false,
		},
	},
})
