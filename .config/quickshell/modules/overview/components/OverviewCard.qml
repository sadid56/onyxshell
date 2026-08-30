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
    signal droppedAt(real gx, real gy)

    radius: 20
    color: isHovered || isSelected || dragMouse.drag.active
           ? (theme ? Qt.alpha(theme.getColor("surfaceVariant"), 0.85) : "#282020")
           : (theme ? Qt.alpha(theme.getColor("surface"), 0.75) : "#1a1414")

    border.width: dragMouse.drag.active ? 2 : 1
    border.color: dragMouse.drag.active
                  ? (theme ? theme.getColor("primary") : "#cba6f7")
                  : (isHovered || isSelected
                     ? (theme ? theme.getColor("outline") : "#605050")
                     : (theme ? Qt.alpha(theme.getColor("outlineVariant"), 0.35) : "#382c2c"))

    property real dragProgress: {
        if (!dragMouse.drag.active) return 0.0;
        var totalDist = Math.max(120, dragMouse.startY - 30);
        var curMoved = dragMouse.startY - cardRoot.y;
        var raw = Math.min(1.0, Math.max(0.0, curMoved / totalDist));
        return Math.pow(raw, 1.25);
    }

    readonly property real targetMinScale: Math.max(0.18, Math.min(0.40, 145.0 / Math.max(100, cardRoot.width)))

    scale: dragMouse.drag.active ? (1.0 - (dragProgress * (1.0 - targetMinScale))) : 1.0
    z: dragMouse.drag.active ? 999 : (isSelected ? 2 : 1)
    opacity: dragMouse.drag.active ? 0.88 : 1.0

    layer.enabled: dragMouse.drag.active
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: "#80000000"
        shadowBlur: 0.8
        shadowVerticalOffset: 8
    }

    Behavior on scale {
        enabled: dragMouse.drag.active
        NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }
    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

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
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter
                radius: 12
                z: 20
                color: closeBtnMouse.containsMouse
                       ? (cardRoot.theme ? cardRoot.theme.getColor("errorContainer") : "#ff5555")
                       : "transparent"

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 11
                    font.bold: true
                    color: closeBtnMouse.containsMouse
                           ? (cardRoot.theme ? cardRoot.theme.getColor("onErrorContainer") : "#ffffff")
                           : (cardRoot.theme ? cardRoot.theme.getColor("onSurfaceVariant") : "#aaaaaa")
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
                cardRoot.droppedAt(globalPt.x, globalPt.y);
            }
            cardRoot.x = startX;
            cardRoot.y = startY;
        }

        onEntered: cardRoot.isHovered = true
        onExited: cardRoot.isHovered = false
    }
}
