-- Animations and Easing Curves Configuration
-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
    animations = {
        enabled = true,
    },
})

-- Define curves
hl.curve("smoothOut", { type = "bezier", points = { {0.25, 0.9}, {0.35, 1.0} } })
hl.curve("smoothIn",  { type = "bezier", points = { {0.15, 0.7}, {0.3,  1.0} } })

-- Define individual animation rules
hl.animation({ leaf = "windows",     enabled = true, speed = 4, bezier = "smoothOut" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 4, bezier = "smoothIn", style = "popin 92%" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "default" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "smoothOut" })
