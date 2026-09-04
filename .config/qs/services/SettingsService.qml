import QtQuick
import Quickshell
import Quickshell.Io
import "./components"

Item {
    id: settingsService

    property string accentColor: "auto"
    property int barHeight: 40
    property int cornerRadius: (typeof root !== "undefined" && root.shellConfig) ? root.shellConfig.cornerRadius : (parseInt(Quickshell.env("ROUNDED")) || 16)
    property bool dndEnabled: false
    property var mutedApps: []
    property int notifTimeout: 5

    property string fontFamily: "Noto Sans"
    property string fontMono: "JetBrainsMono Nerd Font"
    property int fontSize: 12

    readonly property string configDir: (typeof root !== "undefined" && root.shellConfig)
        ? root.shellConfig.quickshellDir
        : (Quickshell.env("HOME") + "/.config/qs")
    readonly property string settingsFilePath: configDir + "/user_settings.json"

    FileView {
        id: settingsFile
        path: settingsService.settingsFilePath
        watchChanges: true
        onLoaded: loadSettings()
        onTextChanged: loadSettings()
    }

    Timer {
        id: fileCheckTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (settingsFile && typeof settingsFile.reload === "function") {
                settingsFile.reload();
            }
            loadSettings();
        }
    }

    Process {
        id: settingsReader
        command: ["cat", settingsService.settingsFilePath]
        stdout: StdioCollector {
            onStreamFinished: {
                var content = this.text ? this.text.trim() : "";
                if (content && content.length > 0) {
                    settingsService.loadFromJson(content);
                }
            }
        }
    }

    MutedAppsHelper { id: mutedHelper }

    property var rootTheme: null
    property bool isInternalSave: false

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
            if (cleanHex.length > 0) {
                var hyprCmd = "hyprctl keyword general:col.active_border \"rgb(" + cleanHex + ")\" && hyprctl keyword group:col.border_active \"rgba(" + cleanHex + "cc)\" && hyprctl reload config-only";
                Quickshell.execDetached(["bash", "-c", hyprCmd]);
            }
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

    property var catppuccinPalette: ({
        "mauve": "#cba6f7",
        "lavender": "#b4befe",
        "blue": "#89b4fa",
        "sapphire": "#74c7ec",
        "sky": "#89dceb",
        "teal": "#94e2d5",
        "green": "#a6e3a1",
        "yellow": "#f9e2af",
        "peach": "#fab387",
        "maroon": "#eba0ac",
        "red": "#f38ba8",
        "pink": "#f5c2e7",
        "flamingo": "#f2cdcd",
        "rosewater": "#f5e0dc"
    })

    function getSettingsObject() {
        return {
            accentColor: settingsService.accentColor,
            barHeight: settingsService.barHeight,
            cornerRadius: settingsService.cornerRadius,
            dndEnabled: settingsService.dndEnabled,
            mutedApps: settingsService.mutedApps,
            fontFamily: settingsService.fontFamily,
            fontMono: settingsService.fontMono,
            fontSize: settingsService.fontSize,
            catppuccinAccents: settingsService.catppuccinPalette
        };
    }

    function resolveColor(val) {
        if (!val || val === "" || val === "auto") return "auto";
        var lower = String(val).toLowerCase().trim();
        if (catppuccinPalette[lower]) return catppuccinPalette[lower];
        return val;
    }

    function triggerMatugenUpdate(rawVal) {
        var hex = resolveColor(rawVal);
        if (!hex || hex === "" || hex === "auto") {
            var wpScript = "WALLPAPER=$(cat \"" + configDir + "/current_wallpaper\" 2>/dev/null) ; if [ -n \"$WALLPAPER\" ] && [ -f \"$WALLPAPER\" ]; then matugen image \"$WALLPAPER\" --source-color-index 0 -t scheme-content -m dark ; fi";
            matugenProc.targetHex = "";
            matugenProc.command = ["bash", "-c", wpScript];
            matugenProc.running = false;
            matugenProc.running = true;
        } else {
            matugenProc.targetHex = hex;
            matugenProc.command = ["matugen", "color", "hex", hex, "-t", "scheme-content", "-m", "dark"];
            matugenProc.running = false;
            matugenProc.running = true;
        }
    }

    function applyAccentColor(hex) {
        settingsService.accentColor = (!hex || hex === "") ? "auto" : hex;
        saveSettings();
        triggerMatugenUpdate(settingsService.accentColor);
    }

    function saveSettings() {
        isInternalSave = true;
        var str = JSON.stringify(getSettingsObject(), null, 2);
        Quickshell.execDetached(["bash", "-c", "printf '%s' \"$1\" > \"$2\"", "save-settings", str, settingsFilePath]);
        Qt.callLater(() => { isInternalSave = false; });
    }

    function loadFromJson(jsonStr) {
        try {
            var data = JSON.parse(jsonStr);
            var prevAccent = settingsService.accentColor;
            var prevFont = settingsService.fontFamily;
            var prevMono = settingsService.fontMono;
            var prevSize = settingsService.fontSize;

            if (data.accentColor !== undefined) settingsService.accentColor = data.accentColor;
            if (data.barHeight !== undefined && data.barHeight > 0) settingsService.barHeight = data.barHeight;
            if (data.cornerRadius !== undefined && data.cornerRadius > 0) settingsService.cornerRadius = data.cornerRadius;
            if (data.dndEnabled !== undefined) settingsService.dndEnabled = data.dndEnabled;
            if (Array.isArray(data.mutedApps)) settingsService.mutedApps = data.mutedApps;
            if (data.notifTimeout !== undefined) settingsService.notifTimeout = data.notifTimeout;
            if (data.fontFamily !== undefined && data.fontFamily !== "") settingsService.fontFamily = data.fontFamily;
            if (data.fontMono !== undefined && data.fontMono !== "") settingsService.fontMono = data.fontMono;
            if (data.fontSize !== undefined && data.fontSize > 0) settingsService.fontSize = data.fontSize;
            if (data.catppuccinAccents && typeof data.catppuccinAccents === "object") {
                settingsService.catppuccinPalette = Object.assign({}, settingsService.catppuccinPalette, data.catppuccinAccents);
            }

            if (!isInternalSave) {
                if (data.accentColor !== undefined && data.accentColor !== prevAccent) {
                    triggerMatugenUpdate(data.accentColor);
                }
                if ((data.fontFamily && data.fontFamily !== prevFont) || (data.fontMono && data.fontMono !== prevMono) || (data.fontSize && data.fontSize !== prevSize)) {
                    syncSystemFonts();
                }
            }
        } catch (e) {}
    }

    function loadSettings() {
        var fileText = "";
        try {
            if (typeof settingsFile.text === "function") {
                fileText = settingsFile.text();
            } else {
                fileText = settingsFile.text;
            }
        } catch (e) {}

        if (fileText && fileText.trim().length > 0) {
            loadFromJson(fileText);
        } else {
            settingsReader.running = false;
            settingsReader.running = true;
        }
    }
}
