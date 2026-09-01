-----------------------------
---- APPEARANCE & LAYOUT ----
-----------------------------
local rounded = tonumber(os.getenv("ROUNDED")) or 16
local border_width = 0
local gaps_in = 5
local gaps_out = 8
local active_opacity = 1.0
local inactive_opacity = 1.0
local layout_mode = "dwindle"

package.loaded["theme.colors"] = nil
local has_colors, colors = pcall(require, "theme.colors")
local active_col = (has_colors and colors.primary) and ("rgb(" .. colors.primary:gsub("#", "") .. ")") or "rgb(ffb3b4)"
local inactive_col = (has_colors and colors.outline_variant) and ("rgb(" .. colors.outline_variant:gsub("#", "") .. ")")
	or "rgb(574142)"
local group_active_col = (has_colors and colors.primary) and ("rgba(" .. colors.primary:gsub("#", "") .. "cc)")
	or "rgba(ffb3b4cc)"
local group_inactive_col = (has_colors and colors.outline_variant)
		and ("rgba(" .. colors.outline_variant:gsub("#", "") .. "55)")
	or "rgba(47464c55)"

hl.config({
	xwayland = {
		enabled = false,
	},

	general = {
		gaps_in = gaps_in,
		gaps_out = gaps_out,
		border_size = border_width,
		col = {
			active_border = active_col,
			inactive_border = inactive_col,
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = layout_mode,
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
		active_opacity = active_opacity,
		inactive_opacity = inactive_opacity,
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

	misc = {
		vrr = 1,
		animate_manual_resizes = false,
		animate_mouse_windowdragging = false,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		force_default_wallpaper = 0,
		on_focus_under_fullscreen = 1,
		focus_on_activate = true,
		always_follow_on_dnd = true,
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
