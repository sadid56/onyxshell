import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../../components/ui" as UI

Rectangle {
    id: cardRoot

    property var theme
    property var clientData: null
    property bool isSelected: false
    property bool isHovered: false

    signal selectWindow()
    signal closeWindow()
    signal draggingAt(real gx, real gy)
    signal droppedAt(var client, real gx, real gy)

    radius: 20
    color: isHovered || isSelected || dragMouse.drag.active
           ? (theme ? theme.getColor("surfaceVariant") : "#282020")
           : (theme ? theme.getColor("surface") : "#1a1414")

    border.width: dragMouse.drag.active ? 2 : 1
    border.color: dragMouse.drag.active
                  ? (theme ? theme.getColor("primary") : "#cba6f7")
                  : (isHovered || isSelected
                     ? (theme ? theme.getColor("outline") : "#605050")
                     : (theme ? theme.getColor("outlineVariant") : "#382c2c"))

    property bool overviewActive: true
    readonly property bool isTopActive: Boolean(clientData && (clientData.focusHistoryID === 0 || cardRoot.isSelected))

    property real dragProgress: {
        if (!dragMouse.drag.active) return 0.0;
        var totalDist = Math.max(120, dragMouse.startY - 30);
        var curMoved = dragMouse.startY - cardRoot.y;
        var raw = Math.min(1.0, Math.max(0.0, curMoved / totalDist));
        return Math.pow(raw, 1.25);
    }

    readonly property real targetMinScale: Math.max(0.18, Math.min(0.40, 145.0 / Math.max(100, cardRoot.width)))

    scale: {
        if (dragMouse.drag.active) return 1.0 - (dragProgress * (1.0 - targetMinScale));
        if (!cardRoot.overviewActive) return (isTopActive ? 1.45 : 1.15);
        return 1.0;
    }
    z: dragMouse.drag.active ? 999 : (isTopActive ? 10 : (isSelected ? 2 : 1))
    opacity: 1.0

    layer.enabled: dragMouse.drag.active
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#80000000"
        shadowBlur: 0.8
        shadowVerticalOffset: 8
    }

    Behavior on scale {
        enabled: true
        NumberAnimation {
            duration: dragMouse.drag.active ? 100 : 180
            easing.type: dragMouse.drag.active ? Easing.OutQuad : Easing.OutQuint
        }
    }


    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            spacing: 8

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter

                IconImage {
                    anchors.fill: parent
                    source: {
                        var ic = cardRoot.clientData ? (cardRoot.clientData.icon || "") : "";
                        if (!ic) return "";
                        if (ic.indexOf("/") === 0) return "file://" + ic;
                        return ic;
                    }
                }
            }

            UI.Typography {
                Layout.fillWidth: true
                theme: cardRoot.theme
                variant: "bodySmall"
                font.bold: true
                colorRole: "onSurface"
                text: cardRoot.clientData ? (cardRoot.clientData.title || cardRoot.clientData.class || "Window") : ""
                elide: Text.ElideRight
            }

            Rectangle {
                id: closeBtn
                Layout.preferredWidth: 30
                Layout.preferredHeight: 30
                Layout.alignment: Qt.AlignVCenter
                radius: 15
                z: 20

                color: closeBtnMouse.containsMouse
                       ? (cardRoot.theme ? Qt.alpha(cardRoot.theme.getColor("onSurface"), 0.12) : "#20ffffff")
                       : "transparent"

                border.width: closeBtnMouse.containsMouse ? 1 : 0
                border.color: cardRoot.theme ? Qt.alpha(cardRoot.theme.getColor("outlineVariant"), 0.40) : "#35ffffff"

                scale: closeBtnMouse.pressed ? 0.90 : (closeBtnMouse.containsMouse ? 1.06 : 1.0)
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: {
                        var cfg = (typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : ((typeof root !== "undefined" && root.shellConfig) ? root.shellConfig : null);
                        if (cfg && typeof cfg.getIcon === "function") return cfg.getIcon("actions/dismiss.svg");
                        return "";
                    }
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: closeBtnMouse.containsMouse
                                           ? (cardRoot.theme ? cardRoot.theme.getColor("onSurface") : "#ffffff")
                                           : (cardRoot.theme ? cardRoot.theme.getColor("onSurfaceVariant") : "#a6adc8")
                    }
                }

                MouseArea {
                    id: closeBtnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    z: 25
                    preventStealing: true
                    onPressed: mouse => mouse.accepted = true
                    onReleased: mouse => mouse.accepted = true
                    onClicked: mouse => {
                        mouse.accepted = true;
                        cardRoot.closeWindow();
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            UI.WindowPreview {
                anchors.fill: parent
                address: cardRoot.clientData ? (cardRoot.clientData.address || "") : ""
                live: true
                cornerRadius: 14
                fallbackIcon: cardRoot.clientData ? (cardRoot.clientData.icon || "") : ""
                backgroundColor: cardRoot.theme ? cardRoot.theme.getColor("surface") : "#131314"
            }
        }
    }

    MouseArea {
        id: dragMouse
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        drag.target: cardRoot
        drag.axis: Drag.XAndYAxis

        property real startX: 0
        property real startY: 0

        onPressed: function(mouse) {
            startX = cardRoot.x;
            startY = cardRoot.y;
        }

        onPositionChanged: function(mouse) {
            if (drag.active) {
                var globalPt = dragMouse.mapToItem(null, mouse.x, mouse.y);
                cardRoot.draggingAt(globalPt.x, globalPt.y);
            }
        }

        onReleased: function(mouse) {
            var dist = Math.abs(cardRoot.x - startX) + Math.abs(cardRoot.y - startY);
            if (dist < 10) {
                cardRoot.selectWindow();
            } else {
                var globalPt = dragMouse.mapToItem(null, mouse.x, mouse.y);
                cardRoot.droppedAt(cardRoot.clientData, globalPt.x, globalPt.y);
            }
            cardRoot.x = startX;
            cardRoot.y = startY;
        }

        onEntered: cardRoot.isHovered = true
        onExited: cardRoot.isHovered = false
    }
}
