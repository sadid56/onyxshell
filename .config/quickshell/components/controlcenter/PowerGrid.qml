import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: powerRoot
    Layout.fillWidth: true
    spacing: 8

    property var theme
    property bool expanded: false
    signal closed()

    // Grid of Power Actions with smooth height & opacity transition (Placed ABOVE to expand upwards)
    Item {
        id: gridWrapper
        Layout.fillWidth: true
        implicitHeight: powerRoot.expanded ? powerGrid.implicitHeight : 0
        opacity: powerRoot.expanded ? 1.0 : 0.0
        clip: true

        Behavior on implicitHeight {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200 }
        }

        GridLayout {
            id: powerGrid
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            columns: 2
            rowSpacing: 8
            columnSpacing: 8

            // Lock Screen Button
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: powerRoot.theme.getColor("surfaceVariant")

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰌾"
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        color: powerRoot.theme.getColor("primary")
                    }
                    Text {
                        text: "Lock"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                        color: powerRoot.theme.getColor("onSurface")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.opacity = 0.85
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        powerRoot.closed();
                        Quickshell.execDetached(["hyprlock"]);
                    }
                }
            }

            // Logout Button
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: powerRoot.theme.getColor("surfaceVariant")

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰍃"
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        color: powerRoot.theme.getColor("primary")
                    }
                    Text {
                        text: "Logout"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                        color: powerRoot.theme.getColor("onSurface")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.opacity = 0.85
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        powerRoot.closed();
                        Quickshell.execDetached(["loginctl", "terminate-session", "self"]);
                    }
                }
            }

            // Reboot Button
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: powerRoot.theme.getColor("surfaceVariant")

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: "󰜉"
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        color: powerRoot.theme.getColor("primary")
                    }
                    Text {
                        text: "Reboot"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                        color: powerRoot.theme.getColor("onSurface")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.opacity = 0.85
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        powerRoot.closed();
                        Quickshell.execDetached(["systemctl", "reboot"]);
                    }
                }
            }

            // Shutdown Button
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 10
                color: powerRoot.theme.getColor("surfaceVariant")

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Text {
                        text: ""
                        font.family: "Noto Sans"
                        font.pixelSize: 13
                        color: powerRoot.theme.getColor("error")
                    }
                    Text {
                        text: "Power Off"
                        font.family: "Google Sans Flex, sans-serif"
                        font.pixelSize: 12
                        font.bold: true
                        color: powerRoot.theme.getColor("onSurface")
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: parent.opacity = 0.85
                    onExited: parent.opacity = 1.0
                    onClicked: {
                        powerRoot.closed();
                        Quickshell.execDetached(["systemctl", "poweroff"]);
                    }
                }
            }
        }
    }

    // Header Expand Button (Placed BELOW to act as the anchor)
    Rectangle {
        Layout.fillWidth: true
        height: 40
        radius: 12
        color: powerRoot.theme.getColor("surfaceVariant")

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16

            Text {
                text: ""
                font.family: "Noto Sans"
                font.pixelSize: 14
                color: powerRoot.theme.getColor("error")
            }

            Text {
                text: "Power Options"
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 13
                font.bold: true
                color: powerRoot.theme.getColor("onSurface")
                Layout.fillWidth: true
            }

            Text {
                text: powerRoot.expanded ? "󰅃" : "󰅀"
                font.family: "Noto Sans"
                font.pixelSize: 16
                color: powerRoot.theme.getColor("primary")
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onEntered: parent.opacity = 0.85
            onExited: parent.opacity = 1.0
            onClicked: powerRoot.expanded = !powerRoot.expanded
        }
    }
}
