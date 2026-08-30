import QtQuick
import QtQuick.Layouts
import "../../../components/ui" as UI

Item {
    id: clockRoot
    anchors.fill: parent

    readonly property real contentWidth: clockRow.implicitWidth
    implicitWidth: clockRow.implicitWidth
    implicitHeight: clockRow.implicitHeight

    property var theme
    property var toggleCalendar
    property var toggleNotifications
    property int notifCount: 0
    property bool hasNotif: false

    function getNotifX() {
        var pos = notifArea.mapToItem(null, 0, 0);
        return pos.x + notifArea.width / 2;
    }

    Row {
        id: clockRow
        spacing: 12
        anchors.centerIn: parent

        MouseArea {
            id: clockArea
            width: clockText.implicitWidth
            height: 28
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            enabled: !clockRoot.hasNotif

            onEntered: {
                if (clockRoot.hasNotif) return;
                root.stopLoaderTimerAndActivate(calendarLoader, statusBar.getClockX());
                root.setLoaderInactive(wifiLoader);
                root.setLoaderInactive(notifsLoader);
            }
            onExited: {
                root.restartLoaderTimer(calendarLoader);
            }
            onClicked: {
                if (clockRoot.hasNotif) return;
                root.stopLoaderTimerAndActivate(calendarLoader, statusBar.getClockX());
            }

            UI.Typography {
                id: clockText
                theme: clockRoot.theme
                variant: "bodyMedium"
                font.bold: true
                colorRole: "onSurface"
                anchors.centerIn: parent
            }
        }

        Rectangle {
            width: 1
            height: 14
            color: clockRoot.theme ? clockRoot.theme.getColor("outline") : "#555555"
            opacity: 0.35
            anchors.verticalCenter: parent.verticalCenter
        }

        MouseArea {
            id: notifArea
            width: 20
            height: 28
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            enabled: !clockRoot.hasNotif

            onEntered: {
                if (clockRoot.hasNotif) return;
                root.stopLoaderTimerAndActivate(notifsLoader, clockRoot.getNotifX());
                root.setLoaderInactive(wifiLoader);
                root.setLoaderInactive(calendarLoader);
            }
            onExited: {
                root.restartLoaderTimer(notifsLoader);
            }
            onClicked: {
                if (clockRoot.hasNotif) return;
                root.stopLoaderTimerAndActivate(notifsLoader, clockRoot.getNotifX());
            }

            UI.Icon {
                size: 16
                anchors.centerIn: parent
                icon: ((typeof shellConfig !== "undefined" && shellConfig) ? shellConfig : root.shellConfig).getNotificationIcon(
                    (typeof root !== "undefined" && root.dndEnabled),
                    clockRoot.notifCount > 0
                )
                color: clockRoot.notifCount > 0
                    ? (clockRoot.theme ? clockRoot.theme.getColor("primary") : "#ffb3b4")
                    : (clockRoot.theme ? clockRoot.theme.getColor("onSurface") : "#FFFFFF")
            }
        }
    }

    Timer {
        id: timeTimer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var date = new Date();
            var timeStr = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: true });

            var day = date.getDate();
            var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            var monthStr = months[date.getMonth()];

            clockText.text = timeStr + " • " + day + " " + monthStr;
        }
    }
}
