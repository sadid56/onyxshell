import QtQuick

Text {
    id: typoRoot

    property var theme: (typeof root !== "undefined" && root && root.theme) ? root.theme : null
    property string colorRole: ""
    property bool mono: false
    property string variant: ""

    font.family: {
        if (typoRoot.theme && typoRoot.theme.fontFamily && typoRoot.theme.fontFamily !== "") {
            return typoRoot.theme.fontFamily;
        }
        if (typeof root !== "undefined" && root && root.settingsService && root.settingsService.fontFamily) {
            return root.settingsService.fontFamily;
        }
        return "";
    }

    readonly property int baseSize: {
        if (typoRoot.theme && typoRoot.theme.fontSize > 0) return typoRoot.theme.fontSize;
        if (typeof root !== "undefined" && root && root.settingsService && root.settingsService.fontSize > 0) return root.settingsService.fontSize;
        return 12;
    }

    readonly property int fontDelta: baseSize - 12

    font.pixelSize: {
        var s = 12;
        switch (variant) {
            case "displayLarge": s = 32; break;
            case "displayMedium": s = 26; break;
            case "titleLarge": s = 22; break;
            case "titleMedium": s = 18; break;
            case "titleSmall": s = 14; break;
            case "bodyLarge": s = 14; break;
            case "bodyMedium": s = 13; break;
            case "bodySmall": s = 11; break;
            case "labelMedium": s = 12; break;
            case "labelSmall": s = 10; break;
            case "caption": s = 10; break;
            case "mono": s = 12; break;
            default: s = 12; break;
        }
        return Math.max(8, s + fontDelta);
    }

    font.weight: {
        switch (variant) {
            case "displayLarge":
            case "displayMedium":
            case "titleLarge":
            case "titleMedium":
                return Font.Bold;
            case "titleSmall":
                return Font.DemiBold;
            case "bodyMedium":
            case "labelMedium":
            case "labelSmall":
                return Font.Medium;
            case "bodyLarge":
            case "bodySmall":
            case "caption":
            default:
                return Font.Normal;
        }
    }

    color: {
        if (colorRole !== "" && typoRoot.theme) {
            return typoRoot.theme.getColor(colorRole);
        }
        if (variant === "bodySmall" || variant === "caption" || variant === "labelSmall") {
            return typoRoot.theme ? typoRoot.theme.getColor("onSurfaceVariant") : "#919096";
        }
        if (variant === "mono") {
            return typoRoot.theme ? typoRoot.theme.getColor("primary") : "#c5c5d8";
        }
        return typoRoot.theme ? typoRoot.theme.getColor("onSurface") : "#ffffff";
    }

    renderType: Text.QtRendering
}
