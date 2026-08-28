import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../../../components/ui" as UI
import "../widgets"

PanelWindow {
    id: mediaWindow

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    exclusiveZone: 0

    property bool active: false
    visible: active || morphContainer.opacity > 0.01

    property var theme
    property real targetX: -1
    property var mediaService: typeof root !== "undefined" ? root.mediaService : null

    readonly property int safeWidth: mediaWindow.width > 0 ? mediaWindow.width : 1920
    readonly property int expandedWidth: 380
    readonly property int collapsedWidth: 140
    readonly property int expandedHeight: 136

    property alias closeTimer: closeTimer

    Timer {
        id: closeTimer
        interval: 80
        running: false
        repeat: false
        onTriggered: {
            mediaWindow.active = false;
        }
    }

    onActiveChanged: {
        if (active) {
            closeTimer.stop();
            if (mediaWindow.mediaService && typeof mediaWindow.mediaService.refresh === "function") {
                mediaWindow.mediaService.refresh();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: mediaWindow.active
        onActivated: mediaWindow.active = false
    }

    MouseArea {
        anchors.fill: parent
        enabled: mediaWindow.active
        hoverEnabled: true
        onClicked: mediaWindow.active = false
        onEntered: {
            if (mediaWindow.active) closeTimer.restart();
        }
    }

    Rectangle {
        id: morphContainer

        x: targetX > 0 ? Math.max(10, Math.min(targetX, safeWidth - width - 10)) : 120
        y: 6

        width: mediaWindow.active ? mediaWindow.expandedWidth : mediaWindow.collapsedWidth
        height: mediaWindow.active ? mediaWindow.expandedHeight : 34
        radius: mediaWindow.active ? 20 : 16
        color: mediaWindow.theme ? mediaWindow.theme.getColor("surface") : "#1e1e2e"
        clip: true

        opacity: mediaWindow.active ? 1.0 : 0.0

        Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: mediaWindow.active
            shadowColor: "#60000000"
            shadowBlur: 1.0
            shadowVerticalOffset: 8
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onEntered: closeTimer.stop()
            onPositionChanged: closeTimer.stop()
        }

        Item {
            anchors.fill: parent
            anchors.margins: 6
            opacity: mediaWindow.active ? 1.0 : 0.0

            Behavior on opacity {
                NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
            }

            MediaControls {
                id: mediaControlsWidget
                anchors.fill: parent
                theme: mediaWindow.theme
                mediaService: mediaWindow.mediaService
            }
        }
    }
}
