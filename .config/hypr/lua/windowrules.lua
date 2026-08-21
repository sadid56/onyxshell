hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "grouped-window-border",
    match = { group = true },
    border_size = 2,
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})

hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
})

hl.layer_rule({
	name         = "quickshell-style",
	match        = { namespace = "quickshell" },
	blur         = true,
	ignore_alpha = 0.3,
	animation    = "fade",
})

hl.window_rule({
    name      = "xdg-float",
    match     = { class = "xdg-desktop-portal-gtk" },
    float     = true,
    center    = true,
    size      = { 1100, 750 },
    animation = "popin 90%",
})

hl.window_rule({
    name      = "dropdown-terminal",
    match     = { class = "^(kitty-dropdown)$" },
    workspace = "special:dropdown",
    float     = true,
    size      = { 1200, 600 },
    center    = true,
    opaque    = true,
    opacity   = 1.0,
})
