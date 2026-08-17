import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import "../../../components/ui" as UI

RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    spacing: 8

    property var theme
    property string uptimeStr: "Up 0m"
    property string currentProfile: "performance"
    property bool powerProfileExpanded: false
    property bool powerMenuExpanded: false

    property var hyprpickerProc
    property var screenshotProc

    signal togglePowerProfile()
    signal togglePowerMenu()
    signal closeRequested()

    RowLayout {
        spacing: 6
        Layout.alignment: Qt.AlignVCenter

        IconImage {
            width: 17
            height: 17
            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("clock.svg")
            Layout.alignment: Qt.AlignVCenter
            layer.enabled: true
            layer.effect: MultiEffect {
                colorization: 1.0
                colorizationColor: headerRoot.theme ? headerRoot.theme.getColor("primary") : "#ffb3b4"
            }
        }

        Text {
            text: headerRoot.uptimeStr
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 12
            font.bold: true
            color: headerRoot.theme ? headerRoot.theme.getColor("onSurface") : "#f0dede"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Item { Layout.fillWidth: true }

    UI.Button {
        theme: headerRoot.theme
        icon: {
            var cfg = (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig);
            if (headerRoot.currentProfile === "performance") return cfg.getIcon("performance.svg");
            if (headerRoot.currentProfile === "power-saver") return cfg.getIcon("leaf-two.svg");
            return cfg.getIcon("memory.svg");
        }
        text: {
            if (headerRoot.currentProfile === "performance") return "Performance";
            if (headerRoot.currentProfile === "power-saver") return "Power Saver";
            return "Balanced";
        }
        active: headerRoot.powerProfileExpanded
        onClicked: headerRoot.togglePowerProfile()
    }

    UI.Button {
        theme: headerRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("eyedropper-filled.svg")
        onClicked: {
            headerRoot.closeRequested();
            if (headerRoot.hyprpickerProc) {
                headerRoot.hyprpickerProc.running = false;
                headerRoot.hyprpickerProc.running = true;
            }
        }
    }

    UI.Button {
        theme: headerRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("crop.svg")
        onClicked: {
            headerRoot.closeRequested();
            if (headerRoot.screenshotProc) {
                headerRoot.screenshotProc.running = false;
                headerRoot.screenshotProc.running = true;
            }
        }
    }

    UI.Button {
        theme: headerRoot.theme
        icon: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("power.svg")
        active: headerRoot.powerMenuExpanded
        onClicked: headerRoot.togglePowerMenu()
    }
}
