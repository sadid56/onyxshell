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
	match        = { namespace = "^(quickshell)$" },
	blur         = true,
	ignore_alpha = 0.3,
	animation    = "none",
})

hl.layer_rule({
	name         = "quickshell-overview-style",
	match        = { namespace = "^(quickshell-overview)$" },
	blur         = false,
	animation    = "none",
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
    size      = { 1520, 500 },
    move      = "200 570",
    opaque    = true,
    opacity   = 1.0,
})


hl.window_rule({
    name  = "pip-video",
    match = { title = "^(Picture-in-Picture)$" },
    float = true,
    pin   = true,
    size  = { 520, 292 },
})

hl.window_rule({
    name   = "dev-utils-float",
    match  = { class = "^(pavucontrol|blueman-manager|nm-connection-editor|org.pulseaudio.pavucontrol|zenity)$" },
    float  = true,
    center = true,
})

hl.window_rule({
    name   = "nautilus-float",
    match  = { class = "^(org.gnome.Nautilus|nautilus)$" },
    float  = true,
    center = true,
    size   = { 1200, 750 },
})

hl.window_rule({
    name   = "yazi-float",
    match  = { class = "^(yazi)$" },
    float  = true,
    center = true,
    size   = { 1200, 750 },
})

hl.window_rule({
    name   = "yazi-title-float",
    match  = { title = "^(yazi|Yazi:.*)$" },
    float  = true,
    center = true,
    size   = { 1200, 750 },
})

hl.window_rule({
    name   = "timeshift-float",
    match  = { class = "^(Timeshift-gtk|timeshift-gtk|timeshift)$" },
    float  = true,
    center = true,
    size   = { 1100, 700 },
})

hl.window_rule({
    name   = "localsend-float",
    match  = { class = "^(localsend|LocalSend|org.localsend.localsend_app|localsend_app)$" },
    float  = true,
    center = true,
    size   = { 900, 650 },
})

hl.window_rule({
    name   = "calculator-float",
    match  = { class = "^(org.gnome.Calculator|gnome-calculator|Calculator)$" },
    float  = true,
    center = true,
    size   = { 400, 600 },
})

hl.window_rule({
    name   = "calendar-float",
    match  = { class = "^(org.gnome.Calendar|gnome-calendar|Calendar)$" },
    float  = true,
    center = true,
    size   = { 900, 650 },
})

hl.window_rule({
    name      = "discord-special",
    match     = { class = "^(discord|vesktop|Discord)$" },
    workspace = "special:magic",
})
