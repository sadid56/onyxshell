import QtQuick
import Quickshell.Io

Item {
    id: theme

    property var colors: ({})

    readonly property var defaults: {
        "primary": "#3574d4",
        "onPrimary": "#ffffff",
        "primaryContainer": "#dbe1ff",
        "onPrimaryContainer": "#00174c",
        "secondary": "#595d72",
        "onSecondary": "#ffffff",
        "secondaryContainer": "#dde1f9",
        "onSecondaryContainer": "#161b2c",
        "error": "#ba1a1a",
        "onError": "#ffffff",
        "errorContainer": "#ffdad6",
        "onErrorContainer": "#410002",
        "background": "#fbf8fd",
        "onBackground": "#1b1b21",
        "surface": "#fbf8fd",
        "onSurface": "#1b1b21",
        "surfaceVariant": "#e2e1ec",
        "onSurfaceVariant": "#45464f",
        "outline": "#757680",
        "shadow": "#000000"
    }

    function getColor(key) {
        if (colors && colors[key] !== undefined) {
            return colors[key];
        }
        return defaults[key];
    }

    FileView {
        id: colorsFile
        path: "/home/sadid/.config/quickshell/colors.json"
        watchChanges: true
        onTextChanged: {
            var fileText = (typeof colorsFile.text === "function") ? colorsFile.text() : colorsFile.text;
            if (fileText && typeof fileText.trim === "function" && fileText.trim().length > 0) {
                try {
                    theme.colors = JSON.parse(fileText);
                } catch (e) {
                    console.log("Failed to parse colors.json: " + e.message);
                    theme.colors = theme.defaults;
                }
            }
        }
    }

    Component.onCompleted: {
        var fileText = (typeof colorsFile.text === "function") ? colorsFile.text() : colorsFile.text;
        if (fileText && fileText.trim().length > 0) {
            try {
                theme.colors = JSON.parse(fileText);
            } catch (e) {
                theme.colors = theme.defaults;
            }
        } else {
            theme.colors = theme.defaults;
        }
    }

    function reloadColors() {
        colorsFile.path = "";
        colorsFile.path = "/home/sadid/.config/quickshell/colors.json";
    }
}
