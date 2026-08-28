import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../../components/ui" as UI
import "../bar/widgets"

PanelWindow {
    id: powerWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || morphContainer.height > 40.5

    property var theme: (typeof root !== "undefined" && root && root.theme) ? root.theme : null
    property real targetX: -1
    property var statusBar: null
    property alias closeTimer: closeTimer
    property int hoveredIndex: -1

    readonly property int safeWidth: powerWindow.width > 0 ? powerWindow.width : 1920
    readonly property int expandedWidth: 220
    readonly property int collapsedWidth: (statusBar && statusBar.rightIslandBaseWidth > 0) ? statusBar.rightIslandBaseWidth : 230
    readonly property int expandedHeight: 220

    Timer {
        id: closeTimer
        interval: 80
        repeat: false
        onTriggered: powerWindow.active = false
    }

    readonly property var powerActions: [
        { action: "lock", label: "Lock", icon: "system/lock-closed.svg", key: "L", isDanger: false, colorRole: "primary" },
        { action: "logout", label: "Log Out", icon: "system/logout.svg", key: "E", isDanger: false, colorRole: "tertiary" },
        { action: "reboot", label: "Restart", icon: "system/arrow-clockwise-filled.svg", key: "R", isDanger: false, colorRole: "primary" },
        { action: "shutdown", label: "Power Off", icon: "system/power.svg", key: "P", isDanger: true, colorRole: "error" }
    ]

    function askConfirmation(options) {
        powerWindow.active = false;
        if (typeof root !== "undefined" && typeof root.confirm === "function") root.confirm(options);
        else if (typeof popupManager !== "undefined" && popupManager.confirmationModal) popupManager.confirmationModal.ask(options);
    }

    function executePowerAction(action) {
        if (action === "lock") {
            askConfirmation({
                title: "Lock Screen",
                message: "Are you sure you want to lock the screen?",
                icon: "system/lock-closed.svg",
                confirmText: "Lock",
                isDanger: false,
                onConfirm: () => {
                    var cfg = (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig);
                    var home = cfg ? cfg.homeDir : Quickshell.env("HOME");
                    Quickshell.execDetached(["sh", "-c", "pidof hyprlock || hyprlock -c " + home + "/.config/hypr/config/hyprlock.conf"]);
                }
            });
        } else if (action === "logout") {
            askConfirmation({
                title: "Log Out",
                message: "Are you sure you want to log out of your session?",
                icon: "system/logout.svg",
                confirmText: "Log Out",
                isDanger: false,
                onConfirm: () => {
                    Quickshell.execDetached(["sh", "-c", "hyprctl dispatch exit || loginctl terminate-user $USER || pkill -U $UID -9 -f Hyprland"]);
                }
            });
        } else if (action === "reboot") {
            askConfirmation({
                title: "Restart Computer",
                message: "Are you sure you want to restart your computer?",
                icon: "system/arrow-clockwise-filled.svg",
                confirmText: "Restart",
                isDanger: false,
                onConfirm: () => { Quickshell.execDetached(["systemctl", "reboot"]); }
            });
        } else if (action === "shutdown") {
            askConfirmation({
                title: "Power Off",
                message: "Are you sure you want to power off the system?",
                icon: "system/power.svg",
                confirmText: "Power Off",
                isDanger: true,
                onConfirm: () => { Quickshell.execDetached(["systemctl", "poweroff"]); }
            });
        }
    }

    property int selectedIndex: 0
    property bool mouseWasInside: false

    onActiveChanged: {
        if (active) {
            closeTimer.stop();
            mouseWasInside = false;
            selectedIndex = 0;
            hoveredIndex = -1;
            keyFocusItem.forceActiveFocus();
        }
    }

    Item {
        id: keyFocusItem
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
        Keys.onRightPressed: {
            if (selectedIndex === 0) selectedIndex = 1;
            else if (selectedIndex === 2) selectedIndex = 3;
            else selectedIndex = 0;
        }
        Keys.onLeftPressed: {
            if (selectedIndex === 1) selectedIndex = 0;
            else if (selectedIndex === 3) selectedIndex = 2;
            else selectedIndex = 1;
        }
        Keys.onDownPressed: {
            if (selectedIndex === 0) selectedIndex = 2;
            else if (selectedIndex === 1) selectedIndex = 3;
            else selectedIndex = 0;
        }
        Keys.onUpPressed: {
            if (selectedIndex === 2) selectedIndex = 0;
            else if (selectedIndex === 3) selectedIndex = 1;
            else selectedIndex = 2;
        }
        Keys.onTabPressed: {
            selectedIndex = (selectedIndex + 1) % 4;
        }
        Keys.onBacktabPressed: {
            selectedIndex = (selectedIndex + 3) % 4;
        }
    }

    Shortcut { sequence: "Escape"; enabled: powerWindow.active; onActivated: powerWindow.active = false }
    Shortcut { sequence: "l"; enabled: powerWindow.active; onActivated: executePowerAction("lock") }
    Shortcut { sequence: "e"; enabled: powerWindow.active; onActivated: executePowerAction("logout") }
    Shortcut { sequence: "r"; enabled: powerWindow.active; onActivated: executePowerAction("reboot") }
    Shortcut { sequence: "p"; enabled: powerWindow.active; onActivated: executePowerAction("shutdown") }

    MouseArea {
        anchors.fill: parent
        enabled: powerWindow.active
        hoverEnabled: true
        onClicked: powerWindow.active = false
        onEntered: {
            if (powerWindow.active && powerWindow.mouseWasInside) {
                closeTimer.restart();
            }
        }
        onPositionChanged: {
            if (powerWindow.active && powerWindow.mouseWasInside) {
                closeTimer.restart();
            }
        }
    }

    Corner {
        id: powerLeftCorner
        anchors.top: parent.top
        anchors.right: morphContainer.left
        alignRight: true
        alignBottom: false
        color: powerWindow.theme ? powerWindow.theme.getColor("surface") : "#1e1e2e"
        cornerRadius: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : 16
        opacity: morphContainer.opacity
        visible: morphContainer.opacity > 0.05
    }

    Corner {
        id: powerBottomRightCorner
        anchors.top: morphContainer.bottom
        anchors.right: parent.right
        alignRight: true
        alignBottom: false
        color: powerWindow.theme ? powerWindow.theme.getColor("surface") : "#1e1e2e"
        cornerRadius: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : 16
        opacity: morphContainer.opacity
        visible: morphContainer.opacity > 0.05
    }

    Rectangle {
        id: morphContainer
        anchors.top: parent.top
        anchors.right: parent.right
        width: powerWindow.active ? powerWindow.expandedWidth : powerWindow.collapsedWidth
        height: powerWindow.active ? powerWindow.expandedHeight : 40
        radius: (typeof root !== "undefined" && root && root.settingsService && root.settingsService.cornerRadius !== undefined) ? root.settingsService.cornerRadius : 16
        color: powerWindow.theme ? powerWindow.theme.getColor("surface") : "#1e1e2e"
        clip: true
        opacity: powerWindow.active ? 1.0 : 0.0

        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutQuint } }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: powerWindow.active
            shadowColor: "#60000000"
            shadowBlur: 1.0
            shadowVerticalOffset: 8
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                powerWindow.mouseWasInside = true;
                closeTimer.stop();
            }
            onPositionChanged: {
                powerWindow.mouseWasInside = true;
                closeTimer.stop();
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.radius
            color: parent.color
        }
        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: parent.radius
            color: parent.color
        }

        GridLayout {
            anchors.fill: parent
            anchors.margins: 14
            columns: 2
            rows: 2
            rowSpacing: 10
            columnSpacing: 10
            opacity: powerWindow.active ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutQuad } }

            Repeater {
                model: powerWindow.powerActions
                PowerMenuTile {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    theme: (powerWindow && powerWindow.theme) ? powerWindow.theme : null
                    itemData: modelData
                    isSelected: (powerWindow.selectedIndex === index)
                    onTileClicked: powerWindow.executePowerAction(modelData.action)
                }
            }
        }
    }
}
