import QtQuick
import "../widgets"

BarPill {
    id: netPill

    property var barWindow

    anchors.top: parent.top
    anchors.topMargin: 6
    anchors.right: barWindow ? barWindow.rightIslandRef.left : parent.right
    pillHeight: 34
    pillRadius: 16
    pillColor: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"

    anchors.rightMargin: 8

    readonly property bool hasWifiActive: (typeof wifiLoader !== "undefined" && wifiLoader.loaded && wifiLoader.item && wifiLoader.item.active)
    opacity: hasWifiActive ? 0.0 : 1.0
    active: true
    contentWidth: hasWifiActive ? (320 - 24) : netIndicator.implicitWidth

    function getWifiX() {
        var pos = netPill.mapToItem(null, 0, 0);
        return pos.x + netPill.width;
    }

    MouseArea {
        id: netClickArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: {
            if (typeof root !== "undefined") {
                root.stopLoaderTimerAndActivate(wifiLoader, netPill.getWifiX());
                root.setLoaderInactive(resourcesLoader);
                root.setLoaderInactive(notifsLoader);
                root.setLoaderInactive(calendarLoader);
            }
        }
        onExited: {
            if (typeof root !== "undefined") root.restartLoaderTimer(wifiLoader);
        }
        onClicked: {
            if (typeof root !== "undefined") root.toggleLoaderActive(wifiLoader, netPill.getWifiX());
        }

        NetworkIndicator {
            id: netIndicator
            anchors.centerIn: parent
            theme: barWindow ? barWindow.theme : null
            sysStats: barWindow ? barWindow.sysStats : null
        }
    }
}
