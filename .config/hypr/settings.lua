-- Settings and Tweaks Configuration
-- Reference: https://wiki.hypr.land/Configuring/Variables/

-- Per-device input overrides
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

-- Gestures config
hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- General tweaks and system components
hl.config({
    misc = {
        disable_hyprland_logo     = false,
        on_focus_under_fullscreen = 1,
    },

    cursor = {
        no_hardware_cursors = 0,
    },

    group = {
        groupbar = {
            enabled = false,
        },
    },
})
