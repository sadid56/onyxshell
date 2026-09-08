import QtQuick
import QtQuick.Layouts
import "../widgets"
import "../../../components/ui" as UI

Item {
    id: rightIsland

    property var barWindow
    property var sysStatsIndicator: sysStatsItem
    property var notifButton: notifButtonItem
    property var powerMenuButton: notifButtonItem

    readonly property bool hasResourcesActive: (typeof resourcesLoader !== "undefined" && resourcesLoader.loaded && resourcesLoader.item && resourcesLoader.item.active)
    readonly property bool hasNotifActive: (typeof notifsLoader !== "undefined" && notifsLoader.loaded && notifsLoader.item && notifsLoader.item.active)
    readonly property bool hasRightPopupActive: hasResourcesActive || hasNotifActive
    readonly property real rightIslandBaseWidth: (typeof rightContentRow !== "undefined" && rightContentRow) ? (rightContentRow.implicitWidth + 36) : 230

    anchors.top: parent.top
    anchors.right: parent.right
    height: barWindow ? barWindow.barHeight : 40
    width: hasRightPopupActive ? (hasNotifActive ? 440 : 380) : (barWindow ? barWindow.rightIslandBaseWidth : rightIslandBaseWidth)
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
            id: notifButtonItem
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            function getNotifX() {
                var pos = notifButtonItem.mapToItem(null, 0, 0);
                return pos.x + notifButtonItem.width / 2;
            }

            onEntered: {
                if (typeof root !== "undefined" && root.stopLoaderTimerAndActivate && typeof notifsLoader !== "undefined") {
                    root.stopLoaderTimerAndActivate(notifsLoader, notifButtonItem.getNotifX());
                    if (typeof wifiLoader !== "undefined") root.setLoaderInactive(wifiLoader);
                    if (typeof calendarLoader !== "undefined") root.setLoaderInactive(calendarLoader);
                    if (typeof resourcesLoader !== "undefined") root.setLoaderInactive(resourcesLoader);
                }
            }
            onExited: {
                if (typeof root !== "undefined" && root.restartLoaderTimer && typeof notifsLoader !== "undefined") {
                    root.restartLoaderTimer(notifsLoader);
                }
            }
            onClicked: {
                if (typeof root !== "undefined" && root.toggleLoaderActive && typeof notifsLoader !== "undefined") {
                    root.toggleLoaderActive(notifsLoader, notifButtonItem.getNotifX());
                }
            }

            UI.Icon {
                anchors.centerIn: parent
                size: 16
                icon: {
                    var cfg = ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : (typeof root !== "undefined" ? root.shellConfig : null));
                    if (cfg && cfg.getNotificationIcon) {
                        return cfg.getNotificationIcon((typeof root !== "undefined" && root.dndEnabled), (barWindow ? barWindow.notifCount : 0) > 0);
                    }
                    return "system/notification.svg";
                }
                color: (barWindow && barWindow.notifCount > 0)
                    ? ((barWindow && barWindow.theme) ? barWindow.theme.getColor("primary") : "#ffb3b4")
                    : (notifButtonItem.containsMouse
                        ? ((barWindow && barWindow.theme) ? barWindow.theme.getColor("primary") : "#ffb3b4")
                        : ((barWindow && barWindow.theme) ? barWindow.theme.getColor("onSurface") : "#FFFFFF"))

                Behavior on color { ColorAnimation { duration: 140 } }
            }
        }
    }
}
