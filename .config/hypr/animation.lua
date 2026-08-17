-- Animations and Easing Curves Configuration
-- Reference: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.config({
    animations = {
        enabled = true,
    },
})

-- Define curves
hl.curve("md3_standard", { type = "bezier", points = { {0.2, 0.0}, {0.0, 1.0} } })
hl.curve("md3_decel",    { type = "bezier", points = { {0.05, 0.7}, {0.1, 1.0} } })
hl.curve("md3_accel",    { type = "bezier", points = { {0.3, 0.0}, {0.8, 0.15} } })

-- Define individual animation rules
hl.animation({ leaf = "windows",     enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "md3_decel", style = "popin 60%" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "md3_accel", style = "popin 60%" })
hl.animation({ leaf = "border",      enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "fade",        enabled = true, speed = 3, bezier = "md3_decel" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3.5, bezier = "md3_decel", style = "slide" })
hl.animation({ leaf = "layers",      enabled = true, speed = 2.5, bezier = "md3_decel", style = "fade" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "md3_decel", style = "fade" })
