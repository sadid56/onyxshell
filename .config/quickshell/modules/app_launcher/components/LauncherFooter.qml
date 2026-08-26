import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Rectangle {
    id: footerRoot
    Layout.fillWidth: true
    height: 32
    color: "transparent"

    property var theme
    property int appCount: 0

    signal powerActionRequested(string action)

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        Text {
            text: footerRoot.appCount + " applications"
            font.family: "Google Sans Flex, sans-serif"
            font.pixelSize: 11
            color: footerRoot.theme ? footerRoot.theme.getColor("onSurfaceVariant") : "#8f8f9f"
            Layout.alignment: Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: [
                    { action: "lock", icon: "system/lock-closed.svg", tooltip: "Lock" },
                    { action: "logout", icon: "system/logout.svg", tooltip: "Log Out" },
                    { action: "reboot", icon: "system/arrow-clockwise-filled.svg", tooltip: "Restart" },
                    { action: "shutdown", icon: "system/power.svg", tooltip: "Power Off" }
                ]

                UI.IconButton {
                    theme: footerRoot.theme
                    icon: modelData.icon
                    buttonSize: 24
                    iconSize: 12
                    iconColor: footerRoot.theme ? footerRoot.theme.getColor("onSurfaceVariant") : "#8f8f9f"
                    hoverIconColor: footerRoot.theme ? footerRoot.theme.getColor("primary") : "#ffb3b4"
                    onClicked: footerRoot.powerActionRequested(modelData.action)
                }
            }
        }
    }
}
