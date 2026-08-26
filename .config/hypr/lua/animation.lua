hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("smooth_decel", { type = "bezier", points = { {0.2, 0.95}, {0.3, 1.0} } })
hl.curve("md3_accel",    { type = "bezier", points = { {0.3, 0.0}, {0.8, 0.15} } })

hl.animation({ leaf = "windows",          enabled = true, speed = 3.0, bezier = "smooth_decel", style = "popin 80%" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 3.0, bezier = "smooth_decel", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 2.4, bezier = "md3_accel",    style = "popin 80%" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 3.2, bezier = "smooth_decel" })
hl.animation({ leaf = "border",           enabled = true, speed = 8.0, bezier = "default" })
hl.animation({ leaf = "fade",             enabled = true, speed = 2.5, bezier = "smooth_decel" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.4, bezier = "smooth_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.2, bezier = "smooth_decel", style = "slidevert" })
hl.animation({ leaf = "layers",           enabled = true, speed = 2.4, bezier = "smooth_decel", style = "fade" })
