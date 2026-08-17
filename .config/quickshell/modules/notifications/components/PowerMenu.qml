import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets

Item {
    id: powerRoot

    property var theme
    property bool expanded: false
    signal closed()

    Layout.fillWidth: true
    implicitHeight: expanded ? contentCol.implicitHeight : 0
    opacity: expanded ? 1.0 : 0.0
    visible: expanded || opacity > 0.01
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: 140 }
    }

    Item {
        id: cardWrapper
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        implicitHeight: contentCol.implicitHeight

        property int hoveredIndex: -1
        property int lastIndex: 0

        Rectangle {
            id: hoverPill
            x: 0
            width: parent.width
            height: 38
            radius: 10
            color: powerRoot.theme ? powerRoot.theme.getColor("surfaceVariant") : "#524343"
            opacity: cardWrapper.hoveredIndex >= 0 ? 1.0 : 0.0
            y: cardWrapper.lastIndex * (38 + 4)

            Behavior on y {
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
            Behavior on opacity {
                NumberAnimation { duration: 140 }
            }
        }

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            spacing: 4
            z: 1

            Repeater {
                model: [
                    { id: "lock", name: "Lock", icon: "lock-closed.svg" },
                    { id: "logout", name: "Logout", icon: "open-filled.svg" },
                    { id: "reboot", name: "Reboot", icon: "arrow-clockwise-filled.svg" },
                    { id: "poweroff", name: "Power Off", icon: "power.svg" }
                ]

                delegate: Item {
                    id: powerItem
                    Layout.fillWidth: true
                    height: 38

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        IconImage {
                            width: 19
                            height: 19
                            source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon(modelData.icon)
                            layer.enabled: true
                            layer.effect: MultiEffect {
                                colorization: 1.0
                                colorizationColor: (cardWrapper.hoveredIndex === index) ?
                                       (powerRoot.theme ? powerRoot.theme.getColor("primary") : "#ffb3b4") :
                                       (powerRoot.theme ? powerRoot.theme.getColor("onSurface") : "#f0dede")
                            }
                        }

                        Text {
                            text: modelData.name
                            font.family: "Google Sans Flex, sans-serif"
                            font.pixelSize: 12
                            font.bold: true
                            color: (cardWrapper.hoveredIndex === index) ?
                                   (powerRoot.theme ? powerRoot.theme.getColor("primary") : "#ffb3b4") :
                                   (powerRoot.theme ? powerRoot.theme.getColor("onSurface") : "#f0dede")
                            Layout.fillWidth: true

                            Behavior on color { ColorAnimation { duration: 120 } }
                        }
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: {
                            cardWrapper.hoveredIndex = index;
                            cardWrapper.lastIndex = index;
                        }
                        onExited: {
                            if (cardWrapper.hoveredIndex === index) {
                                cardWrapper.hoveredIndex = -1;
                            }
                        }
                        onClicked: {
                            powerRoot.closed();
                            if (modelData.id === "lock") {
                                Quickshell.execDetached(["hyprlock"]);
                            } else if (modelData.id === "logout") {
                                Quickshell.execDetached(["loginctl", "terminate-session", "self"]);
                            } else if (modelData.id === "reboot") {
                                Quickshell.execDetached(["systemctl", "reboot"]);
                            } else if (modelData.id === "poweroff") {
                                Quickshell.execDetached(["systemctl", "poweroff"]);
                            }
                        }
                    }
                }
            }
        }
    }
}
