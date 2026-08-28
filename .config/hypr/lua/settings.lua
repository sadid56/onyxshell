local home = os.getenv("HOME")
local user_settings = {}
local sf = io.open(home .. "/.config/quickshell/user_settings.json", "r")
if sf then
	local content = sf:read("*all")
	sf:close()
	local rad = content:match([["cornerRadius"%s*:%s*(%d+)]])
	if rad then user_settings.cornerRadius = tonumber(rad) end
	local bw = content:match([["borderWidth"%s*:%s*(%d+)]])
	if bw then user_settings.borderWidth = tonumber(bw) end
	local gi = content:match([["gapsIn"%s*:%s*(%d+)]])
	if gi then user_settings.gapsIn = tonumber(gi) end
	local go = content:match([["gapsOut"%s*:%s*(%d+)]])
	if go then user_settings.gapsOut = tonumber(go) end
	local ao = content:match([["activeOpacity"%s*:%s*([%d%.]+)]])
	if ao then user_settings.activeOpacity = tonumber(ao) end
	local io = content:match([["inactiveOpacity"%s*:%s*([%d%.]+)]])
	if io then user_settings.inactiveOpacity = tonumber(io) end
	local lay = content:match([["layout"%s*:%s*"([^"]+)"]])
	if lay then user_settings.layout = lay end
	local fm = content:match([["followMouse"%s*:%s*(%a+)]])
	if fm then user_settings.followMouse = (fm == "true" and 1 or 0) end
	local ns = content:match([["touchpadNaturalScroll"%s*:%s*(%a+)]])
	if ns then user_settings.touchpadNaturalScroll = (ns == "true") end
	local dOut = content:match([["displayOutput"%s*:%s*"([^"]+)"]]) or "eDP-1"
	local dRes = content:match([["displayRes"%s*:%s*"([^"]+)"]])
	local dHz = content:match([["displayHz"%s*:%s*(%d+)]])
	if dRes and dHz then
		user_settings.displayOutput = dOut
		user_settings.displayRes = dRes
		user_settings.displayHz = tonumber(dHz)
		hl.monitor({
			output = dOut,
			mode = dRes .. "@" .. dHz,
			position = "auto",
			scale = 1,
		})
	end
end



local rounded = user_settings.cornerRadius or tonumber(os.getenv("ROUNDED")) or 16
local border_width = user_settings.borderWidth ~= nil and user_settings.borderWidth or 0
local gaps_in = user_settings.gapsIn or 5
local gaps_out = user_settings.gapsOut or 10
local active_opacity = user_settings.activeOpacity or 1.0
local inactive_opacity = user_settings.inactiveOpacity or 1.0
local layout_mode = user_settings.layout or "dwindle"
local follow_mouse = user_settings.followMouse ~= nil and user_settings.followMouse or 1
local natural_scroll = user_settings.touchpadNaturalScroll ~= nil and user_settings.touchpadNaturalScroll or true

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

	input = {
		follow_mouse = follow_mouse,
		float_switch_override_focus = 0,
		mouse_refocus = true,
		touchpad = {
			natural_scroll = natural_scroll,
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
