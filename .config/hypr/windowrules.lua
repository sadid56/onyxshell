-- Window and Layer Rules Configuration
-- Reference: https://wiki.hypr.land/Configuring/Window-Rules/


hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

-- Hyprland-run floating
hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

---------------------
---- LAYER RULES ----
---------------------

hl.layer_rule({
	name         = "rofi-style",
	match        = { namespace = "rofi" },
	blur         = true,
	dim_around   = true,
	animation    = "popin 85%",
	ignore_alpha = 0.3,
})

hl.layer_rule({
	name         = "quickshell-style",
	match        = { namespace = "quickshell" },
	blur         = true,
	ignore_alpha = 0.3,
	animation    = "fade",
})

----------------------
---- WINDOW RULES ----
----------------------
hl.window_rule({
    name      = "xdg-float",
    match     = { class = "xdg-desktop-portal-gtk" },
    float     = true,
    center    = true,
    size      = { 1100, 750 },
    animation = "popin 90%",
})

hl.window_rule({
    name      = "sysmon-preview",
    match     = { class = "^(floating_mem)$" },
    float     = true,
    center    = true,
    size      = { 1000, 600 },
    animation = "popin 90%",
    dim_around = true,
})

hl.window_rule({
    name      = "dropdown-terminal",
    match     = { class = "^(kitty-dropdown)$" },
    workspace = "special:dropdown",
    float     = true,
    size      = { 1200, 600 },
    center    = true,
})


