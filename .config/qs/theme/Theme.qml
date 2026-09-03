import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: theme

    property var colors: ({})

    readonly property var defaults: {
        "primary": "#c5c5d8",
        "onPrimary": "#2e2f3e",
        "primaryContainer": "#434453",
        "onPrimaryContainer": "#e1dfe7",
        "secondary": "#c7c5ce",
        "onSecondary": "#303036",
        "secondaryContainer": "#46464d",
        "onSecondaryContainer": "#e1dfe7",
        "error": "#ffb4ab",
        "onError": "#690005",
        "errorContainer": "#93000a",
        "onErrorContainer": "#ffdad6",
        "background": "#131314",
        "onBackground": "#e5e1e3",
        "surface": "#131314",
        "onSurface": "#e5e1e3",
        "surfaceVariant": "#28292e",
        "onSurfaceVariant": "#c8c5cc",
        "outline": "#919096",
        "outlineVariant": "#46464c",
        "shadow": "#000000"
    }

    property string fontFamily: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.fontFamily)
        ? root.settingsService.fontFamily
        : ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.defaultFont : "")

    property string fontMono: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.fontMono)
        ? root.settingsService.fontMono
        : ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig.defaultFontMono : "")

    property int fontSize: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.fontSize)
        ? root.settingsService.fontSize
        : 12

    function getFont() {
        return fontFamily;
    }

    function getFontMono() {
        return fontMono;
    }

    function getColor(key) {
        if (colors && colors[key] !== undefined) {
            return colors[key];
        }
        return defaults[key];
    }

    readonly property string colorsJsonPath: ((typeof root !== "undefined" && root && root.shellConfig) ? root.shellConfig.quickshellDir : (Quickshell.env("HOME") + "/.config/qs")) + "/colors.json"

    FileView {
        id: colorsFile
        path: theme.colorsJsonPath
        blockLoading: true
        onLoaded: {
            loadFromFile();
        }
    }

    Process {
        id: colorReader
        command: ["cat", theme.colorsJsonPath]
        stdout: StdioCollector {
            onStreamFinished: {
                var content = this.text;
                if (content && content.trim().length > 0) {
                    try {
                        theme.colors = JSON.parse(content.trim());
                    } catch (e) {
                        console.log("Failed to parse colors JSON:", e);
                    }
                }
            }
        }
    }

    function loadFromFile() {
        var fileText = (typeof colorsFile.text === "function") ? colorsFile.text() : colorsFile.text;
        if (fileText && fileText.trim().length > 0) {
            try {
                theme.colors = JSON.parse(fileText.trim());
                return;
            } catch (e) {
                theme.colors = theme.defaults;
            }
        } else {
            theme.colors = theme.defaults;
        }
    }

    Component.onCompleted: {
        loadFromFile();
    }

    function reloadColors() {
        if (colorsFile && typeof colorsFile.reload === "function") {
            colorsFile.reload();
            var fileText = (typeof colorsFile.text === "function") ? colorsFile.text() : colorsFile.text;
            if (fileText && fileText.trim().length > 0) {
                try {
                    theme.colors = JSON.parse(fileText.trim());
                } catch (e) {}
            }
        }
        colorReader.running = false;
        colorReader.running = true;
    }
}
