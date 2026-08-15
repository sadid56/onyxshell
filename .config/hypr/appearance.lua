-- Appearance Configuration
-- Reference: https://wiki.hypr.land/Configuring/Variables/

hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,
		border_size = 0,
		col = {
			active_border = "rgb(cba6f7)",
			inactive_border = "rgb(45475a)",
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	debug = {
		vfr = true,
	},

	decoration = {
		rounding = 16,
		rounding_power = 2,
		active_opacity = 1.0,

		blur = {
			enabled = true,
			size = 5,
			passes = 3,
			vibrancy = 0.1696,
		},
	},
})
