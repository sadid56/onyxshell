import QtQuick
import QtQuick.Layouts
import Quickshell
import "./statusbar"

PanelWindow {
    id: barWindow
    anchors { top: true; left: true; right: true }
    // implicitHeight is 56 (40px status bar + 16px corner radius)
    implicitHeight: 56
    color: "transparent"
    
    margins {
        top: 0
        left: 0
        right: 0
    }
    
    // Reserve exactly 40px for the windows so they sit flush below the status bar
    exclusiveZone: 40

    // Theme references passed from root
    property var theme
    property var sysStats
    
    // Callbacks to toggle other components
    property var toggleLauncher
    property var toggleNotifications
    property var toggleCalendar
    property var toggleWifi
    property int notifCount: 0

    function getClockX() {
        var pos = clockItem.mapToItem(null, 0, 0);
        return pos.x + clockItem.width / 2;
    }

    function getWifiX() {
        return sysStatsItem.getWifiX();
    }

    function getNotifX() {
        return sysStatsItem.getNotifX();
    }



    // Main Solid, Opaque Container spanning full width (40px height)
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

            // --- LEFT SECTION: Logo & Workspaces ---
            RowLayout {
                spacing: 16
                Layout.alignment: Qt.AlignVCenter

                // Arch Logo Button
                Text {
                    text: ""
                    font.pixelSize: 16
                    color: barWindow.theme.getColor("primary")
                    font.family: "Noto Sans"
                    font.bold: true
                    Layout.alignment: Qt.AlignVCenter
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: barWindow.toggleLauncher()
                        onEntered: parent.scale = 1.2
                        onExited: parent.scale = 1.0
                    }
                    Behavior on scale {
                        NumberAnimation { duration: 200; easing.type: Easing.OutBack }
                    }
                }

                // Workspaces Indicator Component
                Workspaces {
                    theme: barWindow.theme
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // --- ACTIVE WINDOW TITLE ---
            ActiveWindowTitle {
                theme: barWindow.theme
                Layout.alignment: Qt.AlignVCenter
            }

            // Spacer in the middle to push left and right sections apart
            Item { Layout.fillWidth: true }

            // --- RIGHT SECTION: SysStats, Tray, Power ---
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

        // --- CENTER SECTION: Absolute Centered Clock ---
        Clock {
            id: clockItem
            theme: barWindow.theme
            toggleCalendar: barWindow.toggleCalendar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // --- Bottom-Left Inverted (Concave) Rounded Corner ---
    Corner {
        anchors.top: mainBar.bottom
        anchors.left: parent.left
        alignRight: false
        color: barWindow.theme.getColor("surface")
    }

    // --- Bottom-Right Inverted (Concave) Rounded Corner ---
    Corner {
        anchors.top: mainBar.bottom
        anchors.right: parent.right
        alignRight: true
        color: barWindow.theme.getColor("surface")
    }
}
