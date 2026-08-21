import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../../../core"
import "../../../components/ui" as UIInputs

Item {
    id: headerRoot

    property var theme
    property alias searchText: searchBox.text

    signal searchChanged(string text)
    signal searchCleared()
    signal actionTriggered(string action)
    signal escapePressed()
    signal returnPressed()
    signal downPressed()

    function forceSearchFocus() {
        searchBox.forceFocus();
    }

    implicitHeight: 60
    Layout.fillWidth: true

    RowLayout {
        anchors.fill: parent
        spacing: 12

        // Greeting & Clock
        RowLayout {
            spacing: 10

            Text {
                id: clockText
                text: Qt.formatDateTime(new Date(), "hh:mm AP")
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: theme ? theme.getColor("onSurface") : "#FFFFFF"

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: clockText.text = Qt.formatDateTime(new Date(), "hh:mm AP")
                }
            }

            Rectangle {
                width: 1
                height: 18
                color: theme ? theme.getColor("outline") : "#555555"
                opacity: 0.4
            }

            Text {
                id: dateText
                text: Qt.formatDateTime(new Date(), "ddd, MMM d")
                font.family: "Google Sans Flex, sans-serif"
                font.pixelSize: 12
                color: theme ? theme.getColor("outline") : "#AAAAAA"

                Timer {
                    interval: 60000
                    running: true
                    repeat: true
                    onTriggered: dateText.text = Qt.formatDateTime(new Date(), "ddd, MMM d")
                }
            }
        }

        // Search Input Box
        UIInputs.Input {
            id: searchBox
            Layout.fillWidth: true
            Layout.maximumWidth: 320
            Layout.leftMargin: 28
            theme: headerRoot.theme
            placeholder: "Search apps..."
            icon: typeof shellConfig !== "undefined" ? shellConfig.getIcon("actions/search.svg") : ""

            onEscapePressed: headerRoot.escapePressed()
            onReturnPressed: headerRoot.returnPressed()
            onDownPressed: headerRoot.downPressed()
        }

        Item {
            Layout.fillWidth: true
        }

        // Quick Session Actions
        RowLayout {
            spacing: 8

            // Lock Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: lockMouse.containsMouse 
                       ? (theme ? theme.getColor("surfaceVariant") : "#33FFFFFF") 
                       : (theme ? Qt.rgba(theme.getColor("surfaceVariant").r, theme.getColor("surfaceVariant").g, theme.getColor("surfaceVariant").b, 0.4) : "#15FFFFFF")

                Behavior on color { ColorAnimation { duration: 150 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/lock-closed.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: theme ? theme.getColor("onSurface") : "#FFFFFF"
                    }
                }

                MouseArea {
                    id: lockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.actionTriggered("lock")
                }
            }

            // Logout Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: logoutMouse.containsMouse 
                       ? (theme ? theme.getColor("surfaceVariant") : "#33FFFFFF") 
                       : (theme ? Qt.rgba(theme.getColor("surfaceVariant").r, theme.getColor("surfaceVariant").g, theme.getColor("surfaceVariant").b, 0.4) : "#15FFFFFF")

                Behavior on color { ColorAnimation { duration: 150 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/logout.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: theme ? theme.getColor("onSurface") : "#FFFFFF"
                    }
                }

                MouseArea {
                    id: logoutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.actionTriggered("logout")
                }
            }

            // Reboot Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: rebootMouse.containsMouse 
                       ? (theme ? theme.getColor("surfaceVariant") : "#33FFFFFF") 
                       : (theme ? Qt.rgba(theme.getColor("surfaceVariant").r, theme.getColor("surfaceVariant").g, theme.getColor("surfaceVariant").b, 0.4) : "#15FFFFFF")

                Behavior on color { ColorAnimation { duration: 150 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/arrow-clockwise-filled.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: theme ? theme.getColor("onSurface") : "#FFFFFF"
                    }
                }

                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.actionTriggered("reboot")
                }
            }

            // Shutdown Button
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: powerMouse.containsMouse 
                       ? (theme ? Qt.rgba(theme.getColor("error").r, theme.getColor("error").g, theme.getColor("error").b, 0.3) : "#55FF0000") 
                       : (theme ? Qt.rgba(theme.getColor("surfaceVariant").r, theme.getColor("surfaceVariant").g, theme.getColor("surfaceVariant").b, 0.4) : "#15FFFFFF")

                Behavior on color { ColorAnimation { duration: 150 } }

                IconImage {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: (typeof shellConfig !== "undefined" ? shellConfig : root.shellConfig).getIcon("system/power.svg")
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        colorization: 1.0
                        colorizationColor: powerMouse.containsMouse
                               ? (theme ? theme.getColor("error") : "#FF5555")
                               : (theme ? theme.getColor("onSurface") : "#FFFFFF")
                    }
                }

                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: headerRoot.actionTriggered("shutdown")
                }
            }
        }
    }
}
