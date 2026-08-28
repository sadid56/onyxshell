import QtQuick
import QtQuick.Layouts
import "../widgets"
import "../../../components/ui" as UI

Item {
    id: rightIsland

    property var barWindow
    property var sysStatsIndicator: sysStatsItem
    property var powerMenuButton: powerButtonItem

    readonly property bool hasResourcesActive: (typeof resourcesLoader !== "undefined" && resourcesLoader.loaded && resourcesLoader.item && resourcesLoader.item.active)
    readonly property bool hasPowerActive: (typeof powerMenuLoader !== "undefined" && powerMenuLoader.loaded && powerMenuLoader.item && powerMenuLoader.item.active)
    readonly property bool hasRightPopupActive: hasResourcesActive || hasPowerActive
    readonly property real rightIslandBaseWidth: (typeof rightContentRow !== "undefined" && rightContentRow) ? (rightContentRow.implicitWidth + 36) : 230

    anchors.top: parent.top
    anchors.right: parent.right
    height: barWindow ? barWindow.barHeight : 40
    width: hasResourcesActive ? 380 : (hasPowerActive ? 220 : (barWindow ? barWindow.rightIslandBaseWidth : rightIslandBaseWidth))
    Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

    Corner {
        anchors.top: parent.top
        anchors.right: rightIsland.left
        alignRight: true
        alignBottom: false
        color: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"
        cornerRadius: barWindow ? barWindow.barCornerRadius : 16
    }

    Rectangle {
        anchors.fill: parent
        color: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"
        radius: barWindow ? barWindow.barCornerRadius : 16

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
    }

    RowLayout {
        id: rightContentRow
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12
        opacity: 1.0

        SysStatsIndicator {
            id: sysStatsItem
            theme: barWindow ? barWindow.theme : null
            sysStats: barWindow ? barWindow.sysStats : null
            toggleNotifications: barWindow ? barWindow.toggleNotifications : null
            toggleWifi: barWindow ? barWindow.toggleWifi : null
            notifCount: barWindow ? barWindow.notifCount : 0
            opacity: rightIsland.hasRightPopupActive ? 0.0 : 1.0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Rectangle {
            width: 1
            height: 14
            color: (barWindow && barWindow.theme) ? barWindow.theme.getColor("outline") : "#555555"
            opacity: rightIsland.hasRightPopupActive ? 0.0 : 0.35
            Behavior on opacity { NumberAnimation { duration: 150 } }
            Layout.alignment: Qt.AlignVCenter
        }

        MouseArea {
            id: powerButtonItem
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered: {
                if (typeof root !== "undefined" && root.stopLoaderTimerAndActivate && typeof powerMenuLoader !== "undefined" && typeof statusBar !== "undefined") {
                    root.stopLoaderTimerAndActivate(powerMenuLoader, statusBar.getPowerX());
                    if (typeof resourcesLoader !== "undefined") root.setLoaderInactive(resourcesLoader);
                    if (typeof wifiLoader !== "undefined") root.setLoaderInactive(wifiLoader);
                }
            }
            onExited: {
                if (typeof root !== "undefined" && root.restartLoaderTimer && typeof powerMenuLoader !== "undefined") {
                    root.restartLoaderTimer(powerMenuLoader);
                }
            }
            onClicked: {
                if (typeof root !== "undefined" && root.toggleLoaderActive && typeof powerMenuLoader !== "undefined" && typeof statusBar !== "undefined") {
                    root.toggleLoaderActive(powerMenuLoader, statusBar.getPowerX());
                }
            }

            UI.Icon {
                anchors.centerIn: parent
                size: 16
                icon: "system/power.svg"
                color: powerButtonItem.containsMouse
                    ? ((barWindow && barWindow.theme) ? barWindow.theme.getColor("error") : "#ff5555")
                    : ((barWindow && barWindow.theme) ? barWindow.theme.getColor("onSurface") : "#FFFFFF")

                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }
    }
}
