import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../../components/ui" as UI

PanelWindow {
    id: powerWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || modalBackdrop.opacity > 0.01

    property var theme: (typeof root !== "undefined" && root && root.theme) ? root.theme : null
    property real targetX: -1
    property var statusBar: null
    property int selectedIndex: 0

    readonly property var powerActions: [
        { action: "lock", label: "Lock", subLabel: "Secure session", icon: "system/lock-closed.svg", key: "L", role: "primary" },
        { action: "logout", label: "Log Out", subLabel: "End current session", icon: "system/logout.svg", key: "E", role: "secondary" },
        { action: "reboot", label: "Restart", subLabel: "Reboot device", icon: "system/arrow-clockwise-filled.svg", key: "R", role: "tertiary" },
        { action: "shutdown", label: "Power Off", subLabel: "Shut down PC", icon: "system/power.svg", key: "P", role: "error" }
    ]

    function executePowerAction(action) {
        powerWindow.active = false;
        if (typeof root !== "undefined" && typeof root.closeAllPopups === "function") {
            root.closeAllPopups();
        }

        if (action === "lock") {
            var cfg = (typeof shellConfig !== "undefined" ? shellConfig : (typeof root !== "undefined" ? root.shellConfig : null));
            var home = cfg ? cfg.homeDir : Quickshell.env("HOME");
            Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock -c " + home + "/.config/hypr/config/hyprlock.conf"]);
        } else if (action === "logout") {
            Quickshell.execDetached(["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER || pkill -U $UID -9 -f Hyprland"]);
        } else if (action === "reboot") {
            Quickshell.execDetached(["systemctl", "reboot"]);
        } else if (action === "shutdown") {
            Quickshell.execDetached(["systemctl", "poweroff"]);
        }
    }

    onActiveChanged: {
        if (active) {
            selectedIndex = 0;
            keyFocusItem.forceActiveFocus();
        }
    }

    Item {
        id: keyFocusItem
        anchors.fill: parent
        focus: powerWindow.active

        Keys.onEscapePressed: powerWindow.active = false
        Keys.onReturnPressed: {
            if (selectedIndex >= 0 && selectedIndex < powerActions.length) {
                executePowerAction(powerActions[selectedIndex].action);
            }
        }
        Keys.onEnterPressed: {
            if (selectedIndex >= 0 && selectedIndex < powerActions.length) {
                executePowerAction(powerActions[selectedIndex].action);
            }
        }
        Keys.onRightPressed: selectedIndex = (selectedIndex + 1) % 4
        Keys.onLeftPressed: selectedIndex = (selectedIndex + 3) % 4
        Keys.onTabPressed: selectedIndex = (selectedIndex + 1) % 4
        Keys.onBacktabPressed: selectedIndex = (selectedIndex + 3) % 4
    }

    Shortcut { sequence: "Escape"; enabled: powerWindow.active; onActivated: powerWindow.active = false }
    Shortcut { sequence: "l"; enabled: powerWindow.active; onActivated: executePowerAction("lock") }
    Shortcut { sequence: "e"; enabled: powerWindow.active; onActivated: executePowerAction("logout") }
    Shortcut { sequence: "r"; enabled: powerWindow.active; onActivated: executePowerAction("reboot") }
    Shortcut { sequence: "p"; enabled: powerWindow.active; onActivated: executePowerAction("shutdown") }

    // Ambient Fullscreen Dim Backdrop
    Rectangle {
        id: modalBackdrop
        anchors.fill: parent
        color: "#000000"
        opacity: powerWindow.active ? 0.72 : 0.0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: powerWindow.active = false
        }
    }

    // Centered Cinematic Container
    ColumnLayout {
        id: centerGroup
        anchors.centerIn: parent
        spacing: 32

        scale: powerWindow.active ? 1.0 : 0.95
        opacity: powerWindow.active ? 1.0 : 0.0

        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // Top Cinematic Time & Date
        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 4

            UI.Typography {
                Layout.alignment: Qt.AlignHCenter
                theme: powerWindow.theme
                text: Qt.formatDateTime(new Date(), "hh:mm AP")
                variant: "headlineLarge"
                font.bold: true
                font.pixelSize: 42
                colorRole: "onSurface"
            }

            UI.Typography {
                Layout.alignment: Qt.AlignHCenter
                theme: powerWindow.theme
                text: Qt.formatDateTime(new Date(), "dddd, dd MMMM yyyy")
                variant: "titleMedium"
                font.pixelSize: 15
                colorRole: "outline"
            }
        }

        // 4 Large Luxury Material 3 Floating Cards
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 185
            Layout.minimumHeight: 185
            Layout.maximumHeight: 185
            spacing: 16

            Repeater {
                model: powerWindow.powerActions
                PowerMenuTile {
                    theme: powerWindow.theme
                    itemData: modelData
                    isSelected: (powerWindow.selectedIndex === index)
                    onHoverEntered: powerWindow.selectedIndex = index
                    onTileClicked: powerWindow.executePowerAction(modelData.action)
                }
            }
        }
    }
}
