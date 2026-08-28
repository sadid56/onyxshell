import QtQuick
import Quickshell
import Quickshell.Io
import "./components"

Item {
    id: settingsService

    property string accentColor: "auto"
    property int cornerRadius: 16
    property int borderWidth: 1
    property int gapsIn: 5
    property int gapsOut: 10
    property real activeOpacity: 1.0
    property real inactiveOpacity: 0.95
    property string layout: "dwindle"
    property string animationsPreset: "smooth"
    property bool followMouse: true

    property bool dndEnabled: false
    property var mutedApps: []
    property int notifTimeout: 5

    property bool dockEnabled: true
    property bool dockLivePreview: true
    property bool dockAutoShowEmpty: true
    property int dockIconSize: 28
    property int dockSpacing: 6
    property var dockPinnedApps: []

    property string displayOutput: "eDP-1"
    property string displayRes: "1920x1080"
    property int displayHz: 144

    property bool nightLightEnabled: false
    property int nightLightTemp: 4500
    property bool touchpadNaturalScroll: true
    property bool touchpadTapToClick: true
    property real touchpadSpeed: 0.0

    property string fontFamily: "JetBrainsMono Nerd Font"
    property string fontMono: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    readonly property string configDir: (typeof root !== "undefined" && root.shellConfig)
        ? root.shellConfig.quickshellDir
        : (Quickshell.env("HOME") + "/.config/quickshell")
    readonly property string settingsFilePath: configDir + "/user_settings.json"

    FileView {
        id: settingsFile
        path: settingsService.settingsFilePath
        onLoaded: loadSettings()
    }

    HyprlandSettingsSync { id: hyprSync }
    MutedAppsHelper { id: mutedHelper }

    property var rootTheme: null

    Process {
        id: matugenProc
        property string targetHex: ""
        onExited: (exitCode, exitStatus) => {
            if (settingsService.rootTheme && typeof settingsService.rootTheme.reloadColors === "function") {
                settingsService.rootTheme.reloadColors();
            } else if (typeof root !== "undefined" && root.rootTheme && typeof root.rootTheme.reloadColors === "function") {
                root.rootTheme.reloadColors();
            }
            var cleanHex = targetHex.replace("#", "");
            var hyprCmd = "hyprctl keyword general:col.active_border \"rgb(" + cleanHex + ")\" && hyprctl keyword group:col.border_active \"rgba(" + cleanHex + "cc)\" && hyprctl reload config-only";
            Quickshell.execDetached(["bash", "-c", hyprCmd]);
        }
    }

    Component.onCompleted: loadSettings()

    function isAppMuted(app) {
        return mutedHelper.isAppMuted(app, mutedApps);
    }

    function setMuteApp(app, isMuted) {
        mutedApps = mutedHelper.computeMutedApps(app, isMuted, mutedApps);
        saveSettings();
    }

    function getSettingsObject() {
        return {
            accentColor: settingsService.accentColor, cornerRadius: settingsService.cornerRadius,
            borderWidth: settingsService.borderWidth, gapsIn: settingsService.gapsIn, gapsOut: settingsService.gapsOut,
            activeOpacity: settingsService.activeOpacity, inactiveOpacity: settingsService.inactiveOpacity,
            layout: settingsService.layout, animationsPreset: settingsService.animationsPreset,
            followMouse: settingsService.followMouse, dndEnabled: settingsService.dndEnabled,
            mutedApps: settingsService.mutedApps, displayOutput: settingsService.displayOutput,
            displayRes: settingsService.displayRes, displayHz: settingsService.displayHz,
            nightLightEnabled: settingsService.nightLightEnabled, nightLightTemp: settingsService.nightLightTemp,
            touchpadNaturalScroll: settingsService.touchpadNaturalScroll, touchpadTapToClick: settingsService.touchpadTapToClick,
            touchpadSpeed: settingsService.touchpadSpeed, fontFamily: settingsService.fontFamily,
            fontMono: settingsService.fontMono, fontSize: settingsService.fontSize,
            dockEnabled: settingsService.dockEnabled, dockLivePreview: settingsService.dockLivePreview,
            dockAutoShowEmpty: settingsService.dockAutoShowEmpty, dockIconSize: settingsService.dockIconSize,
            dockSpacing: settingsService.dockSpacing, dockPinnedApps: settingsService.dockPinnedApps
        };
    }

    function cleanAppKey(s) {
        if (!s) return "";
        return String(s).toLowerCase().replace(/\.desktop$/i, "").replace(/[\s\-_.]/g, "").trim();
    }

    function matchApp(pin, app) {
        if (!pin || !app) return false;
        var pName = (pin.name || "").toLowerCase().trim();
        var pExec = (pin.exec || "").toLowerCase().trim();
        var pDId = (pin.desktopId || "").toLowerCase().trim();
        var aName = (app.name || "").toLowerCase().trim();
        var aExec = (app.exec || "").toLowerCase().trim();
        var aDId = (app.desktopId || "").toLowerCase().trim();

        if (pName && pName === aName) return true;
        if (pDId && aDId && pDId === aDId) return true;

        var pParts = pExec ? pExec.split(/\s+/) : [];
        var aParts = aExec ? aExec.split(/\s+/) : [];
        var pBin = pParts.length > 0 ? pParts[0].split("/").pop().toLowerCase() : "";
        var aBin = aParts.length > 0 ? aParts[0].split("/").pop().toLowerCase() : "";

        if ((aBin === "kitty" || aBin === "alacritty" || aBin === "foot" || aBin === "wezterm") && aParts.length > 2) {
            var eIdx = aParts.indexOf("-e");
            if (eIdx !== -1 && (eIdx + 1) < aParts.length) aBin = aParts[eIdx + 1].split("/").pop().toLowerCase();
        }
        if ((pBin === "kitty" || pBin === "alacritty" || pBin === "foot" || pBin === "wezterm") && pParts.length > 2) {
            var peIdx = pParts.indexOf("-e");
            if (peIdx !== -1 && (peIdx + 1) < pParts.length) pBin = pParts[peIdx + 1].split("/").pop().toLowerCase();
        }
        if (pBin && aBin && pBin === aBin && pBin !== "sh" && pBin !== "bash" && pBin !== "env" && pBin !== "python" && pBin !== "python3") return true;

        var cpName = cleanAppKey(pName), caName = cleanAppKey(aName);
        var cpExec = cleanAppKey(pBin || pExec), caExec = cleanAppKey(aBin || aExec);
        var cpDId = cleanAppKey(pDId), caDId = cleanAppKey(aDId);
        var pList = [cpName, cpExec, cpDId], aList = [caName, caExec, caDId];

        for (var i = 0; i < pList.length; i++) {
            var p = pList[i];
            if (!p || p.length < 3) continue;
            for (var j = 0; j < aList.length; j++) {
                var a = aList[j];
                if (!a || a.length < 3) continue;
                if (p === a) return true;
            }
        }
        return false;
    }

    function isAppPinned(app) {
        if (!app || !Array.isArray(dockPinnedApps)) return false;
        for (var i = 0; i < dockPinnedApps.length; i++) {
            if (matchApp(dockPinnedApps[i], app)) return true;
        }
        return false;
    }

    function togglePinnedApp(app) {
        if (!app) return;
        var arr = Array.isArray(dockPinnedApps) ? dockPinnedApps.slice() : [];
        var idx = -1;
        for (var i = 0; i < arr.length; i++) {
            if (matchApp(arr[i], app)) {
                idx = i;
                break;
            }
        }
        if (idx >= 0) {
            arr.splice(idx, 1);
        } else {
            arr.push({ name: app.name || "", icon: app.icon || "", exec: app.exec || "", comment: app.comment || "" });
        }
        dockPinnedApps = arr;
        saveSettings();
    }

    function applyDisplayMode(monName, res, hz, scale) {
        settingsService.displayOutput = monName || "eDP-1";
        settingsService.displayRes = res;
        settingsService.displayHz = hz;
        saveSettings();
        hyprSync.applyDisplayMode(monName, res, hz, scale);
    }

    function applyFont(name, size) {
        if (name && name !== "") settingsService.fontFamily = name;
        if (size !== undefined && size > 0) settingsService.fontSize = size;
        saveSettings();
        var fontCmd = "gsettings set org.gnome.desktop.interface font-name '" + settingsService.fontFamily + " " + settingsService.fontSize + "' ; "
            + "gsettings set org.gnome.desktop.interface document-font-name '" + settingsService.fontFamily + " " + settingsService.fontSize + "' ; "
            + "gsettings set org.gnome.desktop.interface monospace-font-name '" + settingsService.fontMono + " " + settingsService.fontSize + "'";
        Quickshell.execDetached(["bash", "-c", fontCmd]);
    }

    function applyFontMono(name) {
        if (name && name !== "") settingsService.fontMono = name;
        saveSettings();
        var fontCmd = "gsettings set org.gnome.desktop.interface monospace-font-name '" + settingsService.fontMono + " " + settingsService.fontSize + "'";
        Quickshell.execDetached(["bash", "-c", fontCmd]);
    }

    function applyAccentColor(hex) {
        if (!hex || hex === "" || hex === "auto") {
            settingsService.accentColor = "auto";
            saveSettings();
            var wpScript = "WALLPAPER=$(cat \"" + configDir + "/current_wallpaper\" 2>/dev/null) ; if [ -n \"$WALLPAPER\" ] && [ -f \"$WALLPAPER\" ]; then matugen image \"$WALLPAPER\" --source-color-index 0 -t scheme-content -m dark ; fi";
            matugenProc.targetHex = "";
            matugenProc.command = ["bash", "-c", wpScript];
            matugenProc.running = false;
            matugenProc.running = true;
        } else {
            settingsService.accentColor = hex;
            saveSettings();
            matugenProc.targetHex = hex;
            matugenProc.command = ["matugen", "color", "hex", hex, "-t", "scheme-content", "-m", "dark"];
            matugenProc.running = false;
            matugenProc.running = true;
        }
    }

    function saveSettings() {
        var str = JSON.stringify(getSettingsObject(), null, 2);
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "save-settings", str, settingsFilePath]);
        hyprSync.applyHyprlandSettings(settingsService, rootTheme);
    }

    function loadFromJson(jsonStr) {
        try {
            var data = JSON.parse(jsonStr);
            if (data.accentColor !== undefined) settingsService.accentColor = data.accentColor;
            if (data.cornerRadius !== undefined) settingsService.cornerRadius = data.cornerRadius;
            if (data.borderWidth !== undefined) settingsService.borderWidth = data.borderWidth;
            if (data.gapsIn !== undefined) settingsService.gapsIn = data.gapsIn;
            if (data.gapsOut !== undefined) settingsService.gapsOut = data.gapsOut;
            if (data.activeOpacity !== undefined) settingsService.activeOpacity = data.activeOpacity;
            if (data.inactiveOpacity !== undefined) settingsService.inactiveOpacity = data.inactiveOpacity;
            if (data.layout !== undefined) settingsService.layout = data.layout;
            if (data.animationsPreset !== undefined) settingsService.animationsPreset = data.animationsPreset;
            if (data.followMouse !== undefined) settingsService.followMouse = data.followMouse;
            if (data.dndEnabled !== undefined) settingsService.dndEnabled = data.dndEnabled;
            if (Array.isArray(data.mutedApps)) settingsService.mutedApps = data.mutedApps;
            if (data.notifTimeout !== undefined) settingsService.notifTimeout = data.notifTimeout;
            if (data.nightLightEnabled !== undefined) settingsService.nightLightEnabled = data.nightLightEnabled;
            if (data.nightLightTemp !== undefined) settingsService.nightLightTemp = data.nightLightTemp;
            if (data.touchpadNaturalScroll !== undefined) settingsService.touchpadNaturalScroll = data.touchpadNaturalScroll;
            if (data.touchpadTapToClick !== undefined) settingsService.touchpadTapToClick = data.touchpadTapToClick;
            if (data.touchpadSpeed !== undefined) settingsService.touchpadSpeed = data.touchpadSpeed;
            if (data.fontFamily !== undefined && data.fontFamily !== "") settingsService.fontFamily = data.fontFamily;
            if (data.fontMono !== undefined && data.fontMono !== "") settingsService.fontMono = data.fontMono;
            if (data.fontSize !== undefined && data.fontSize > 0) settingsService.fontSize = data.fontSize;
            if (data.dockEnabled !== undefined) settingsService.dockEnabled = data.dockEnabled;
            if (data.dockLivePreview !== undefined) settingsService.dockLivePreview = data.dockLivePreview;
            if (data.dockAutoShowEmpty !== undefined) settingsService.dockAutoShowEmpty = data.dockAutoShowEmpty;
            if (data.dockIconSize !== undefined && data.dockIconSize > 0) settingsService.dockIconSize = data.dockIconSize;
            if (data.dockSpacing !== undefined && data.dockSpacing >= 0) settingsService.dockSpacing = data.dockSpacing;
            if (Array.isArray(data.dockPinnedApps)) settingsService.dockPinnedApps = data.dockPinnedApps;
        } catch (e) {}
    }

    function loadSettings() {
        var fileText = (typeof settingsFile.text === "function") ? settingsFile.text() : settingsFile.text;
        if (fileText && fileText.trim().length > 0) loadFromJson(fileText);
    }
}
