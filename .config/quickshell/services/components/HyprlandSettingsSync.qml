import QtQuick
import Quickshell

QtObject {
    id: hyprSync

    function applyNightLight(enabled, temp, currentTemp) {
        var isEn = (enabled !== undefined) ? enabled : false;
        var t = temp || currentTemp || 4500;
        var cmd = isEn
            ? "pkill -9 hyprsunset 2>/dev/null ; sleep 0.05 ; hyprctl eval 'hl.exec_cmd([=[hyprsunset -t " + t + "]=])'"
            : "pkill -9 hyprsunset 2>/dev/null";
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    function applyDisplayMode(monName, res, hz, scale) {
        if (!res || !hz) return;
        var mon = monName || "eDP-1";
        var sc = scale || 1;
        var luaCmd = "hyprctl eval 'hl.monitor({ output = [[" + mon + "]], mode = [[" + res + "@" + hz + "]], position = [[auto]], scale = " + sc + " })'";
        Quickshell.execDetached(["bash", "-c", luaCmd]);
    }

    function applyHyprlandSettings(svc, rootTheme) {
        if (!svc) return;
        var hex = (svc.accentColor && svc.accentColor !== "auto") ? svc.accentColor : "";
        var cleanHex = hex ? hex.replace("#", "") : "";
        if (!cleanHex) {
            var thColor = (svc.rootTheme && typeof svc.rootTheme.getColor === "function")
                ? svc.rootTheme.getColor("primary")
                : ((typeof rootTheme !== "undefined" && rootTheme && typeof rootTheme.getColor === "function") ? rootTheme.getColor("primary") : "#c5c5d8");
            cleanHex = thColor ? thColor.replace("#", "") : "c5c5d8";
        }

        var luaCode = "hl.config({"
            + "general = {"
            + "  gaps_in = " + svc.gapsIn + ","
            + "  gaps_out = " + svc.gapsOut + ","
            + "  border_size = " + svc.borderWidth + ","
            + "  layout = [[" + svc.layout + "]],"
            + "  col = { active_border = [[rgb(" + cleanHex + ")]] }"
            + "},"
            + "decoration = {"
            + "  rounding = " + svc.cornerRadius + ","
            + "  active_opacity = " + svc.activeOpacity + ","
            + "  inactive_opacity = " + svc.inactiveOpacity
            + "},"
            + "input = {"
            + "  follow_mouse = " + (svc.followMouse ? 1 : 0) + ","
            + "  touchpad = {"
            + "    natural_scroll = " + (svc.touchpadNaturalScroll ? "true" : "false") + ","
            + "    tap_to_click = " + (svc.touchpadTapToClick ? "true" : "false")
            + "  }"
            + "},"
            + "group = {"
            + "  col = { border_active = [[rgba(" + cleanHex + "cc)]] }"
            + "}"
            + "})";

        var evalCmd = "hyprctl eval '" + luaCode + "'";

        var legacyCmds = [
            "hyprctl keyword decoration:rounding " + svc.cornerRadius,
            "hyprctl keyword general:gaps_in " + svc.gapsIn,
            "hyprctl keyword general:gaps_out " + svc.gapsOut,
            "hyprctl keyword general:border_size " + svc.borderWidth,
            "hyprctl keyword decoration:active_opacity " + svc.activeOpacity,
            "hyprctl keyword decoration:inactive_opacity " + svc.inactiveOpacity,
            "hyprctl keyword general:layout " + svc.layout,
            "hyprctl keyword input:follow_mouse " + (svc.followMouse ? 1 : 0),
            "hyprctl keyword input:touchpad:natural_scroll " + (svc.touchpadNaturalScroll ? "true" : "false"),
            "hyprctl keyword input:touchpad:tap-to-click " + (svc.touchpadTapToClick ? "true" : "false")
        ];

        if (cleanHex !== "") {
            legacyCmds.push("hyprctl keyword general:col.active_border 'rgb(" + cleanHex + ")'");
            legacyCmds.push("hyprctl keyword group:col.border_active 'rgba(" + cleanHex + "cc)'");
        }

        var fullCmd = evalCmd + " ; " + legacyCmds.join(" ; ");
        Quickshell.execDetached(["bash", "-c", fullCmd]);
        applyNightLight(svc.nightLightEnabled, svc.nightLightTemp, svc.nightLightTemp);
    }
}
