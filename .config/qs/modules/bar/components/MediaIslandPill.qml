import QtQuick
import "../widgets"

BarPill {
    id: mediaIslandRoot

    property var barWindow

    anchors.top: parent.top
    anchors.topMargin: 6
    anchors.left: barWindow ? barWindow.leftIslandRef.right : parent.left
    anchors.leftMargin: 8
    pillHeight: barWindow ? Math.max(20, barWindow.barHeight - 6) : 34
    pillRadius: Math.floor(pillHeight / 2)
    pillColor: barWindow ? barWindow.barSurfaceColor : "#1e1e2e"

    readonly property bool hasMediaActive: (typeof mediaLoader !== "undefined" && mediaLoader.loaded && mediaLoader.item && mediaLoader.item.active)
    readonly property bool hasMedia: barWindow && barWindow.mediaService && Boolean(barWindow.mediaService.hasMedia)

    active: hasMedia && !hasMediaActive
    contentWidth: hasMediaActive ? (380 - 24) : (mediaBarItem ? mediaBarItem.implicitWidth : 0)

    function getMediaX() {
        var pos = mediaIslandRoot.mapToItem(null, 0, 0);
        return pos.x;
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onEntered: {
            if (typeof root !== "undefined") {
                root.stopLoaderTimerAndActivate(mediaLoader, mediaIslandRoot.getMediaX());
                root.setLoaderInactive(calendarLoader);
                root.setLoaderInactive(notifsLoader);
                root.setLoaderInactive(wifiLoader);
            }
        }
        onExited: {
            if (typeof root !== "undefined") root.restartLoaderTimer(mediaLoader);
        }
        onClicked: {
            if (typeof root !== "undefined") root.toggleLoaderActive(mediaLoader, mediaIslandRoot.getMediaX());
        }

        MediaBarWidget {
            id: mediaBarItem
            anchors.centerIn: parent
            theme: barWindow ? barWindow.theme : null
            mediaService: barWindow ? barWindow.mediaService : null
        }
    }
}
