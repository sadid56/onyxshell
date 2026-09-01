hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("smooth_decel", { type = "bezier", points = { {0.2, 0.95}, {0.3, 1.0} } })
hl.curve("md3_accel",    { type = "bezier", points = { {0.3, 0.0}, {0.8, 0.15} } })

hl.animation({ leaf = "windows",          enabled = false })
hl.animation({ leaf = "windowsIn",        enabled = false })
hl.animation({ leaf = "windowsOut",       enabled = false })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 3.2, bezier = "smooth_decel" })
hl.animation({ leaf = "border",           enabled = true, speed = 8.0, bezier = "default" })
hl.animation({ leaf = "fade",             enabled = false })
hl.animation({ leaf = "fadeIn",           enabled = false })
hl.animation({ leaf = "fadeOut",          enabled = false })
hl.animation({ leaf = "fadeSwitch",       enabled = false })
hl.animation({ leaf = "fadeShadow",       enabled = false })
hl.animation({ leaf = "fadeDim",          enabled = false })
hl.animation({ leaf = "fadeLayers",       enabled = false })
hl.animation({ leaf = "fadeLayersIn",     enabled = false })
hl.animation({ leaf = "fadeLayersOut",    enabled = false })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 3.4, bezier = "smooth_decel", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3.2, bezier = "smooth_decel", style = "slidevert" })
hl.animation({ leaf = "layers",           enabled = false })
hl.animation({ leaf = "layersIn",         enabled = false })
hl.animation({ leaf = "layersOut",        enabled = false })
