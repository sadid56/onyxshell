import QtQuick
import QtQuick.Layouts
import Quickshell
import "./widgets"
import "../../core"
import "../../components/ui" as UI

PanelWindow {
    id: barWindow
    anchors { top: true; left: true; right: true }
    implicitHeight: 56
    color: "transparent"

    margins {
        top: 0
        left: 0
        right: 0
    }

    exclusiveZone: 40

    property var theme
    property var sysStats
    property var mediaService

    property var toggleLauncher
    property var toggleNotifications
    property var toggleCalendar
    property var toggleWifi
    property var toggleMedia
    property int notifCount: 0

    function getClockX() {
        var pos = clockItem.mapToItem(null, 0, 0);
        return pos.x + clockItem.width / 2;
    }

    function getMediaX() {
        var pos = mediaBarItem.mapToItem(null, 0, 0);
        return pos.x + mediaBarItem.width / 2;
    }

    function getWifiX() {
        return sysStatsItem.getWifiX();
    }

    function getNotifX() {
        return sysStatsItem.getNotifX();
    }

    Rectangle {
        id: mainBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 40
        color: barWindow.theme.getColor("surface")
        border.width: 0

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 20

            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignVCenter

                DistroLogo {
                    id: distroLogoItem
                    Layout.alignment: Qt.AlignVCenter

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: barWindow.toggleLauncher()
                        onEntered: distroLogoItem.scale = 1.2
                        onExited: distroLogoItem.scale = 1.0
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                }

                Workspaces {
                    theme: barWindow.theme
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            UI.Divider {
                theme: barWindow.theme
            }

            MediaBarWidget {
                id: mediaBarItem
                theme: barWindow.theme
                mediaService: barWindow.mediaService
                toggleMedia: barWindow.toggleMedia
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            SysStatsIndicator {
                id: sysStatsItem
                theme: barWindow.theme
                sysStats: barWindow.sysStats
                toggleNotifications: barWindow.toggleNotifications
                toggleWifi: barWindow.toggleWifi
                notifCount: barWindow.notifCount
                Layout.alignment: Qt.AlignVCenter
            }
        }

        Clock {
            id: clockItem
            theme: barWindow.theme
            toggleCalendar: barWindow.toggleCalendar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Corner {
        anchors.top: mainBar.bottom
        anchors.left: parent.left
        alignRight: false
        color: barWindow.theme.getColor("surface")
    }

    Corner {
        anchors.top: mainBar.bottom
        anchors.right: parent.right
        alignRight: true
        color: barWindow.theme.getColor("surface")
    }
}
