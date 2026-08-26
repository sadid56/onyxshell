local rounded = tonumber(os.getenv("ROUNDED")) or 16

local has_colors, colors = pcall(require, "theme.colors")
local active_col = (has_colors and colors.primary) and ("rgb(" .. colors.primary:gsub("#", "") .. ")") or "rgb(ffb3b4)"
local inactive_col = (has_colors and colors.outline_variant) and ("rgb(" .. colors.outline_variant:gsub("#", "") .. ")")
	or "rgb(574142)"
local group_active_col = (has_colors and colors.primary) and ("rgba(" .. colors.primary:gsub("#", "") .. "cc)")
	or "rgba(ffb3b4cc)"
local group_inactive_col = (has_colors and colors.outline_variant)
		and ("rgba(" .. colors.outline_variant:gsub("#", "") .. "55)")
	or "rgba(47464c55)"

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

	render = {
		direct_scanout = 1,
	},

	dwindle = {
		preserve_split = true,
		special_scale_factor = 0.88,
	},

	master = {
		special_scale_factor = 0.88,
	},

	decoration = {
		rounding = rounded,
		rounding_power = 2,
		active_opacity = 1.0,
		dim_special = 0.65,

		blur = {
			enabled = true,
			size = 6,
			passes = 2,
			vibrancy = 0.1696,
			new_optimizations = true,
			ignore_opacity = true,
			special = false,
		},
	},

	input = {
		follow_mouse = 1,
		float_switch_override_focus = 0,
		mouse_refocus = true,
		touchpad = {
			natural_scroll = true,
		},
	},

	misc = {
		vrr = 1,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		on_focus_under_fullscreen = 1,
		focus_on_activate = true,
	},

	cursor = {
		no_hardware_cursors = 0,
		no_warps = true,
		inactive_timeout = 5,
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
